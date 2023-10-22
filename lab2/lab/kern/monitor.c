// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/pmap.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "backtrace", "Display stack backtrace",mon_backtrace},
	{ "showmapping", "Display memory mappings. showmapping l r",mon_showmapping},
	{ "setmapperm" , "setmapperm va C a.Set the permissions of any mapping in the current address space.",mon_setmappingperm},
	{ "vdump", "vdump va1 va2 size.Dump size bytes virtual memory from va1 to va2.",mon_vdump},
	{"pdump","pdump pa1 pa2 size. Dump size bytes physical memory from pa1 to pa2.",mon_pdump},
	{ "x/x", "show the 4 bytes at virturl address va",mon_showmemory}
};

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}


int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	int* ebp = ((int*)read_ebp());
	while (ebp != 0)
	{
		int eip = *(ebp+1);
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",ebp+1,eip,*(ebp+2),*(ebp+3),*(ebp+4),*(ebp+5),*(ebp+6));
		struct Eipdebuginfo info;
		int tmp = debuginfo_eip(eip, &info);
		cprintf("         %s:%d: ",info.eip_file,info.eip_line);
		for (int i=0;i<info.eip_fn_namelen;i++)
			cprintf("%c",info.eip_fn_name[i]);
		cprintf("+%d\n",info.eip_fn_narg);
		ebp = (int*)(*(ebp));
		
	}
	return 0;
}
int htoi(char s[])  //translate from a hex string to int
{  
	int i;  
	int n = 0;  
    if (s[0] == '0' && (s[1]=='x' || s[1]=='X')) i = 2;  
    else i = 0;  
    for (; (s[i] >= '0' && s[i] <= '9') || (s[i] >= 'a' && s[i] <= 'z') || (s[i] >='A' && s[i] <= 'F');++i)  
        if ('a' <= s[i] && s[i] <='f')   
            n = n * 16 + 10 + s[i] - 'a';
        else if ('A' <= s[i] && s[i] <= 'F')
        	n = n * 16+s[i]+10-'A';    
        else   
            n = n * 16 + (s[i] - '0');  
    return n;  
}  
//showmemorymapping
int mon_showmapping(int argc, char **argv, struct Trapframe *tf)
{
	//cprintf("%d\n",argc);
	if (argc != 3)
	{
		cprintf("you should give 2 arguments l and r\n");
		return 0;
	}
	size_t l,r;
	l = htoi(argv[1]);
	r = htoi(argv[2]);
	if (l % PGSIZE != 0 || r % PGSIZE != 0)
	{
		cprintf("invalid l or r\n");
		return 0;
	}
	cprintf("VM          PM      PTE_P  PTE_W  PTE_U\n");
	for (size_t i = l;i<=r;i+=PGSIZE)
	{
		cprintf("%8x  ",i);
		pte_t* pte = pgdir_walk(kern_pgdir,(char*)i,0);
		if (pte == NULL) 
		{
			cprintf("No mapping\n");
			continue;
		}
		physaddr_t pa = *pte;
		cprintf("%8x  %d      %d      %d\n",(pa>>12)<<12,pa&PTE_P,(pa&PTE_W)>>1,(pa&PTE_U)>>2);
	}
	return 0;
}
//set any permision of any pte via va.
int mon_setmappingperm(int argc, char **argv, struct Trapframe *tf)
{
	if (argc != 4)
	{
		cprintf("Wrong argument number.\n");
		return 0;
	}
	int b = argv[3][0]-'0';
	int a = argv[2][0];
	if ((a!='P' && a!='U' && a!='W') || (b!=0 && b!=1))
	{
		cprintf("Invalid input.\n");
		return 0;
	}
	uintptr_t va = htoi(argv[1]);
	if (va % PGSIZE != 0)
	{
		cprintf("va not aligned.\n");
		return 0;
	}
	pte_t *pte = pgdir_walk(kern_pgdir,(char*)va,0);
	if (pte == NULL)
	{
		cprintf("This va has not been mapped.\n");
		return 0;
	}
	unsigned int perm;
	if (a=='P') perm=PTE_P;
	if (a=='U') perm=PTE_U;
	if (a=='W') perm=PTE_W;
	if (b==0) (*pte)&=~perm;
	else (*pte)|=perm;
	cprintf("Set succeed.\n");
	physaddr_t pa = *pte;
	cprintf("VM          PM      PTE_P  PTE_W  PTE_U\n");
	cprintf("%8x  %8x  %d      %d      %d\n",va,(pa>>12)<<12,pa&PTE_P,(pa&PTE_W)>>1,(pa&PTE_U)>>2);
	return 0;
}

int mon_vdump(int argc, char **argv, struct Trapframe *tf)
{
	//What I do is check every byte to see whether it is available.
	if (argc != 4)
	{
		cprintf("Wrong argument number.\n");
		return 0;
	}
	uintptr_t va1 = htoi(argv[1]);
	uintptr_t va2 = htoi(argv[2]);
	size_t size = htoi(argv[3]);
	if (va1 + size > KERNBASE+npages*PGSIZE || va2 + size > KERNBASE+npages*PGSIZE || va1<KERNBASE || va2<KERNBASE)
	{
		cprintf("Invalid virturall address\n");
		return 0;
	}
	for (size_t i=0;i<size;i++)
	{
		pte_t* pte1 = pgdir_walk(kern_pgdir,(char*)(va1+i),0);
		if (pte1==NULL || !((*pte1)&PTE_P))
		{
			cprintf("Source address can't read at %p.\n",va1+i);
			return 0;
		}
		pte_t* pte2 = pgdir_walk(kern_pgdir,(char*)(va2+i),1);
		if (pte2==NULL || (!((*pte2) & PTE_P) || !((*pte2) & PTE_W)))
		{
			cprintf("Purpose address can't write at %p.\n",va2+i);
			return 0;
		}
		size_t offset1 = (va1+i)%PGSIZE;
		size_t offset2 = (va2+i)%PGSIZE;
		*((char*)KADDR(PTE_ADDR(*pte2)) + offset2) = *((char*)KADDR(PTE_ADDR(*pte1)) + offset1);
	}
	cprintf("Succeed.\n");
	return 0;
}
int mon_pdump(int argc, char **argv, struct Trapframe *tf)
{
	if (argc != 4)
	{
		cprintf("Wrong argument number.\n");
		return 0;
	}
	physaddr_t pa1 = htoi(argv[1]);
	physaddr_t pa2 = htoi(argv[2]);
	size_t size = htoi(argv[3]);
	if (pa1 + size > 0xffffffff || pa2 + size > 0xffffffff || pa1<0 || pa2<0)
	{
		cprintf("Invalid physical address\n");
		return 0;
	}
	for (size_t i=0;i<size;i+=PGSIZE)
	{
		char* va1 = KADDR(pa1+i); //there has implemented panic in KADDR so I will not check.
		char* va2 = KADDR(pa2+i);
		for (size_t j=0;j<PGSIZE;j++)
			*(va2+j) = *(va1+j);
	}
	cprintf("Succeed.\n");
	return 0;
}
int mon_showmemory(int argc,char **argv,struct Trapframe *tf)
{
	if (argc != 2)
	{
		cprintf("Wrong argument number.\n");
		return 0;
	}
	uintptr_t va = htoi(argv[1]);
	if (va > KERNBASE+npages*PGSIZE || va<KERNBASE )
	{
		cprintf("Invalid virturall address.\n");
		return 0;
	}
	size_t offset = va % PGSIZE;
	pte_t* pte = pgdir_walk(kern_pgdir,(char*)va,0);
	if (!pte || !((*pte)&PTE_P))
	{
		cprintf("this address not read.\n");
		return 0;
	}
	unsigned char* pa = KADDR(PTE_ADDR(*pte));
	pa += offset;
	cprintf("%p: %x\n",pa,*pa);
	cprintf("%p: %x\n",pa+1,*(pa+1));
	cprintf("%p: %x\n",pa+2,*(pa+2));
	cprintf("%p: %x\n",pa+3,*(pa+3));
	return 0;
}
/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
