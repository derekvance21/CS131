--- lnxsrv11 ---
$ java -version
openjdk version "15.0.2" 2021-01-19
OpenJDK Runtime Environment (build 15.0.2+7-27)
OpenJDK 64-Bit Server VM (build 15.0.2+7-27, mixed mode, sharing)

$ javac -version
javac 15.0.2

$ cat /proc/meminfo
MemTotal:       65794548 kB
MemFree:        54949092 kB
MemAvailable:   63226076 kB
Buffers:          417256 kB
Cached:          7384144 kB
SwapCached:         8092 kB
Active:          4258864 kB
Inactive:        4428508 kB
Active(anon):    1292424 kB
Inactive(anon):   129568 kB
Active(file):    2966440 kB
Inactive(file):  4298940 kB
Unevictable:           0 kB
Mlocked:               0 kB
SwapTotal:      20479996 kB
SwapFree:       16834020 kB
Dirty:                28 kB
Writeback:             0 kB
AnonPages:        876524 kB
Mapped:           140436 kB
Shmem:            536020 kB
Slab:            1643676 kB
SReclaimable:    1503488 kB
SUnreclaim:       140188 kB
KernelStack:        9808 kB
PageTables:        34552 kB
NFS_Unstable:          0 kB
Bounce:                0 kB
WritebackTmp:          0 kB
CommitLimit:    53377268 kB
Committed_AS:    6918592 kB
VmallocTotal:   34359738367 kB
VmallocUsed:      390768 kB
VmallocChunk:   34325399548 kB
HardwareCorrupted:     0 kB
AnonHugePages:     81920 kB
CmaTotal:              0 kB
CmaFree:               0 kB
HugePages_Total:       0
HugePages_Free:        0
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
DirectMap4k:      412132 kB
DirectMap2M:    48861184 kB
DirectMap1G:    17825792 kB

$ cat /proc/cpuinfo
...
model name      : Intel(R) Xeon(R) CPU      E5620 @ 2.40GHz
(16 of these processors)

$ uname -a
Linux lnxsrv06.seas.ucla.edu 3.10.0-1062.9.1.el7.x86_64 #1 SMP Mon Dec 2 08:31:54 EST 2019 x86_64 GNU/Linux

$ cat /etc/os-release
NAME="Red Hat Enterprise Linux Server"
VERSION="7.8 (Maipo)"

--- lnxsrv11 ---
$ cat /proc/cpuinfo
...
model name      : Intel(R) Xeon(R) Silver 4116 CPU @ 2.10GHz
(4 of these processors)

$ uname -a
Linux lnxsrv11.seas.ucla.edu 4.18.0-193.19.1.el8_2.x86_64 #1 SMP Wed Aug 26 15:29:02 EDT 2020 x86_64 x86_64 x86_64 GNU/Linux

$ cat /etc/os-release
NAME="Red Hat Enterprise Linux"
VERSION="8.2 (Ootpa)"

$ javac -version
javac 15.0.2

$ java -version
openjdk version "15.0.2" 2021-01-19
OpenJDK Runtime Environment (build 15.0.2+7-27)
OpenJDK 64-Bit Server VM (build 15.0.2+7-27, mixed mode, sharing)

$ cat /proc/meminfo
MemTotal:       65649184 kB
MemFree:         1978912 kB
MemAvailable:   58730368 kB
Buffers:          122048 kB
Cached:         56040472 kB
SwapCached:        14252 kB
Active:          3994912 kB
Inactive:       55266788 kB
Active(anon):    2967036 kB
Inactive(anon):   283872 kB
Active(file):    1027876 kB
Inactive(file): 54982916 kB
Unevictable:           0 kB
Mlocked:               0 kB
SwapTotal:       8388604 kB
SwapFree:        7177468 kB
Dirty:                60 kB
Writeback:             0 kB
AnonPages:       3083140 kB
Mapped:           354204 kB
Shmem:            151852 kB
KReclaimable:    1462928 kB
Slab:            1894848 kB
SReclaimable:    1462928 kB
SUnreclaim:       431920 kB
KernelStack:       10416 kB
PageTables:        42044 kB
NFS_Unstable:          0 kB
Bounce:                0 kB
WritebackTmp:          0 kB
CommitLimit:    41213196 kB
Committed_AS:    6529092 kB
VmallocTotal:   34359738367 kB
VmallocUsed:           0 kB
VmallocChunk:          0 kB
Percpu:          2324160 kB
HardwareCorrupted:     0 kB
AnonHugePages:    931840 kB
ShmemHugePages:        0 kB
ShmemPmdMapped:        0 kB
HugePages_Total:       0
HugePages_Free:        0
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
Hugetlb:               0 kB
DirectMap4k:     3214748 kB
DirectMap2M:    39776256 kB
DirectMap1G:    24117248 kB