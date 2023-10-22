# Lab2

## question1

the type of `x` is `uintptr_t`.

## question2

|Entry|Base Virtual Address|Points to (logically):|
|---|---|---|
|1023|0xffc00000|Page table for top 4MB of phys memory|
|...|...|page addresses holding RAM|
|960|0xf0000000|KERNBASE.the first page is the page table holding the mappings for the beginning of RAM(RW)|
|959|0xefc00000|Kernel Stack(RW)|
|958|0xef800000|Memory-mapped I/O|
|957|0xef400000|Cur. Page Table (User R-)|
|956|0xef000000|Read only pages|
|...|...|unmapped|
|0|0x0|unmapped|

## question3

We set the PTE_U bit off for user programs. So the processor can check and give a fault if a user program tries to use the kernel only address.

## question4

256MB.Because the page table mappes the first 256MB of pysical memory.

## question5

Because there are 256MB/4KB = 65536 entries in pagetable and 1024 entries in page dirctory, which takes 4byte*(1024+65536) = 266240bytes. Besides, there are also 65536 PageInfo struct, which takes 65536*8byte = 524288bytes. So the overhead is 7905280 bytes = 772KB.

To decrease the overhead, we can use 4MB pages as the first Challenge need to do (but I do not realize).

## question6

After the PE bit in `%cr0` is set and then a long jump.

Mapping both virtual address `0x00000000` and `0xf0000000` to the physical address `0x00000000` allows us to execute on both low and high addresses.

We needs to execute the instructions just after we set PE bit, so we need to acquir its address, which is a low address.

## Challenge

I add some commands to the monitor.

- `showmapping l r`. Show the mapping infomation from virtual address `l` to `r`.
- `setmapperm va C a`. Set the permission bits of a pte entry pointed by virtual address `va` to `a`.C represents which bit to change.
- `vdump va1 va2 size`. Dump the `size` bytes at virtual address `va1` to `va2`.
- `pdump pa1 pa2 size`. Dump the `size` bytes at physical address `pa1` to `pa2`.
- `x/x va`. Show the first 4 bytes starting at the virtual address `va`.

The details are in `kern/monitor.c`.
