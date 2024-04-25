## question1

Some of the interrupt handler need to push *error code*, however, some of don't. There are different requirements for different handlers, so it is clear to use different handlers. Besides, using different handlers also makes the kernel aware of which specific interrupt happens.

## question2

I don't do anything.

Progresses in user mode have no permission to use the handlers that only kernel can visit.

The progress in user mode can't use page fault handler(vector 14), and will cause general protection fault(vector 13).

User shouldn't access all memory and the kernel should protect the memory, so a progress in user mode should not invoke the kernel's page fault handler.

## question3

The IDT contains a descriptor privilege level (dpl)field. Checking `dpl&3` can get the privilege of the interrupt handler.

`SETGATE(idt[T_BRKPT], 1, GD_KT, BRKPT, 3);` to get the breakpoint exception to work.

If the dpl=0 and a user progress access the gate, it will cause a general protection fault.

## question4

To prevent the user from triggering the kernel from executing interrupt handlers,which are meant to be executed only for truly exceptional situations.

Protect the kernel by blocking the user access the kernel.

## Challenge!

I achieve the challenge in exercise 4, which seems to have no grade.