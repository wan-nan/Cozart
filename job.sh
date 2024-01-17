#!/bin/bash
source constant.sh

trace() {
    make toggle-trace-mode
    for app in $@; do
        echo "Tracing $app"
        make clean
        if [[ $app == "boot" ]]; then
            ./trace-kernel.sh /benchmark-scripts/$app.sh;
        else
            ./trace-kernel.sh /benchmark-scripts/$app.sh local;
        fi
        mkdir -p config-db/$linux/$base
        cp final.config.tmp config-db/$linux/$base/$app.config
    done
}

decompose_app() {
    # this function is a helper for application stacks and has no effect for
    # single application
    echo $1 | tr '+' ' '
}

compose() {
    for app in $@; do
        echo "Aggregate $app"
        ./aggregate-config.sh \
            config-db/$linux/$base/base.config \
            config-db/$linux/$base/base-choice.config \
            config-db/$linux/$base/disable.config \
            config-db/$linux/$base/boot.config \
            $(locate_config_file $(decompose_app $app))
        cd $linux
        make clean
        make -j`nproc` LOCALVERSION=-$linux-$base-$app
        mkdir -p $kernelbuild/$linux/$base/$app
        INSTALL_PATH=$kernelbuild/$linux/$base/$app make install
        INSTALL_MOD_PATH=$kernelbuild/$linux/$base/$app make modules_install
        cd $workdir
        make install-kernel-modules
    done
    find $kernelbuild -iname "*.old" | xargs rm -f
}

compose-fc() {
    for app in $@; do
        appconfig=$(mktemp)
        trap "rm $appconfig" EXIT
        cat $workdir/config-db/$linux/$base/$app.config \
            | ./appconfiglet_filter.sh > $appconfig
        cd $linux
        make -j`nproc` mrproper
        ./scripts/kconfig/merge_config.sh -n \
            $workdir/config-db/hypervisors/fc.config $appconfig
        make -j`nproc` LOCALVERSION=-fc-$app
        mkdir -p $kernelbuild/fc/$app
        cp vmlinux $kernelbuild/fc/$app
        INSTALL_PATH=$kernelbuild/fc/$app make install
        INSTALL_MOD_PATH=$kernelbuild/fc/$app make modules_install
        cd $workdir
    done
    find $kernelbuild -iname "*.old" | xargs rm -f
}

benchmark() {
    make toggle-benchmark-mode
    for app in $@; do
        echo "Benchmark $app on cozarted kernel"
        $qemubin -cpu $cpu -enable-kvm -smp $cores -m $mem \
            -kernel $kernelbuild/$linux/$base/$app/vmlinuz* \
            -drive file="$(pwd)/qemu-disk.ext4",if=ide,format=raw \
            -nographic -no-reboot \
            -append "panic=-1 console=ttyS0 root=/dev/sda rw init=/benchmark-scripts/$app.sh" \
            > ./test/$app/$app.cozart.benchresult;

        echo "Benchmark $app on base kernel"
       $qemubin -cpu $cpu -enable-kvm -smp $cores -m $mem \
            -kernel $kernelbuild/$linux/$base/base/vmlinuz* \
            -drive file="$(pwd)/qemu-disk.ext4",if=ide,format=raw \
            -nographic -no-reboot \
            -append "panic=-1 console=ttyS0 root=/dev/sda rw init=/benchmark-scripts/$app.sh" \
            > ./test/$app/$app.base.benchresult;

    done
}

# measure the boot time of kernel
boot-time() {
    make toggle-benchmark-mode
    itr=10
    for app in $@; do
        > ./test/$app/$app.cozart.boot-time
        > ./test/$app/$app.base.boot-time
        # echo "Boot-time $app on cozarted kernel"
        for i in `seq $itr`; do
            echo "$i-th boot"
            
            $qemubin -cpu $cpu -enable-kvm -smp $cores -m $mem \
                -kernel $kernelbuild/$linux/$base/$app/vmlinuz* \
                -drive file="$(pwd)/qemu-disk.ext4",if=ide,format=raw \
                -nographic -no-reboot \
                -append "panic=-1 console=ttyS0 root=/dev/sda rw init=/benchmark-scripts/boot-time.sh cozart" \
                | grep "Boot cozart" >> ./test/$app/$app.cozart.boot-time;

            $qemubin -cpu $cpu -enable-kvm -smp $cores -m $mem \
                    -kernel $kernelbuild/$linux/$base/base/vmlinuz* \
                    -drive file="$(pwd)/qemu-disk.ext4",if=ide,format=raw \
                    -nographic -no-reboot \
                    -append "panic=-1 console=ttyS0 root=/dev/sda rw init=/benchmark-scripts/boot-time.sh baseline" \
                    | grep "Boot baseline" >> ./test/$app/$app.base.boot-time;
        done
        awk '{ sum += $4; n++ } END { if (n > 0) print "avg boot-time = ", sum / n; }' ./test/$app/$app.cozart.boot-time >> ./test/$app/$app.cozart.boot-time
        awk '{ sum += $4; n++ } END { if (n > 0) print "avg boot-time = ", sum / n; }' ./test/$app/$app.base.boot-time >> ./test/$app/$app.base.boot-time
    done
}

# measure the boot time of kernel
mem-usage() {
    make toggle-benchmark-mode
    for app in $@; do
        echo "Mem-usage $app on cozarted kernel"
        $qemubin -cpu $cpu -enable-kvm -smp $cores -m $mem \
            -kernel $kernelbuild/$linux/$base/$app/vmlinuz* \
            -drive file="$(pwd)/qemu-disk.ext4",if=ide,format=raw \
            -nographic -no-reboot \
            -append "panic=-1 console=ttyS0 root=/dev/sda rw init=/benchmark-scripts/mem-usage.sh cozart" \
            ;
            # > $app.cozart.benchresult;

        echo "Mem-usage $app on base kernel"
       $qemubin -cpu $cpu -enable-kvm -smp $cores -m $mem \
            -kernel $kernelbuild/$linux/$base/base/vmlinuz* \
            -drive file="$(pwd)/qemu-disk.ext4",if=ide,format=raw \
            -nographic -no-reboot \
            -append "panic=-1 console=ttyS0 root=/dev/sda rw init=/benchmark-scripts/mem-usage.sh baseline" \
            ;
            # > $app.base.benchresult;

    done
}

action=$1

shift

$action $@;

