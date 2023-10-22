
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 60 11 00       	mov    $0x116000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 60 89 11 f0       	mov    $0xf0118960,%eax
f010004b:	2d 00 83 11 f0       	sub    $0xf0118300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 83 11 f0       	push   $0xf0118300
f0100058:	e8 54 38 00 00       	call   f01038b1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 3d 10 f0       	push   $0xf0103d60
f010006f:	e8 82 2d 00 00       	call   f0102df6 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 d8 16 00 00       	call   f0101751 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 bc 0d 00 00       	call   f0100e42 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 64 89 11 f0 00 	cmpl   $0x0,0xf0118964
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 64 89 11 f0    	mov    %esi,0xf0118964

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 7b 3d 10 f0       	push   $0xf0103d7b
f01000b5:	e8 3c 2d 00 00       	call   f0102df6 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 0c 2d 00 00       	call   f0102dd0 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 d8 48 10 f0 	movl   $0xf01048d8,(%esp)
f01000cb:	e8 26 2d 00 00       	call   f0102df6 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 65 0d 00 00       	call   f0100e42 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 93 3d 10 f0       	push   $0xf0103d93
f01000f7:	e8 fa 2c 00 00       	call   f0102df6 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 c8 2c 00 00       	call   f0102dd0 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 d8 48 10 f0 	movl   $0xf01048d8,(%esp)
f010010f:	e8 e2 2c 00 00       	call   f0102df6 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 85 11 f0    	mov    0xf0118524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 85 11 f0    	mov    %edx,0xf0118524
f0100159:	88 81 20 83 11 f0    	mov    %al,-0xfee7ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 85 11 f0 00 	movl   $0x0,0xf0118524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 83 11 f0 40 	orl    $0x40,0xf0118300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 83 11 f0    	mov    0xf0118300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 00 3f 10 f0 	movzbl -0xfefc100(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 83 11 f0       	mov    %eax,0xf0118300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 83 11 f0    	mov    0xf0118300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 83 11 f0    	mov    %ecx,0xf0118300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 00 3f 10 f0 	movzbl -0xfefc100(%edx),%eax
f0100211:	0b 05 00 83 11 f0    	or     0xf0118300,%eax
f0100217:	0f b6 8a 00 3e 10 f0 	movzbl -0xfefc200(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 83 11 f0       	mov    %eax,0xf0118300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d e0 3d 10 f0 	mov    -0xfefc220(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 ad 3d 10 f0       	push   $0xf0103dad
f010026d:	e8 84 2b 00 00       	call   f0102df6 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 85 11 f0 	movzwl 0xf0118528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 85 11 f0    	mov    %ax,0xf0118528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 85 11 f0    	mov    0xf011852c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 85 11 f0 	addw   $0x50,0xf0118528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 85 11 f0 	movzwl 0xf0118528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 85 11 f0    	mov    %ax,0xf0118528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 85 11 f0 	movzwl 0xf0118528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 85 11 f0 	mov    %dx,0xf0118528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 85 11 f0    	mov    0xf011852c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 85 11 f0 	cmpw   $0x7cf,0xf0118528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 85 11 f0       	mov    0xf011852c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 dd 34 00 00       	call   f01038fe <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 85 11 f0    	mov    0xf011852c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 85 11 f0 	subw   $0x50,0xf0118528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 85 11 f0    	mov    0xf0118530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 85 11 f0 	movzwl 0xf0118528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 85 11 f0 00 	cmpb   $0x0,0xf0118534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 85 11 f0       	mov    0xf0118520,%eax
f01004c3:	3b 05 24 85 11 f0    	cmp    0xf0118524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 85 11 f0    	mov    %edx,0xf0118520
f01004d4:	0f b6 88 20 83 11 f0 	movzbl -0xfee7ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 85 11 f0 00 	movl   $0x0,0xf0118520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 85 11 f0 b4 	movl   $0x3b4,0xf0118530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 85 11 f0 d4 	movl   $0x3d4,0xf0118530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 85 11 f0    	mov    0xf0118530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 85 11 f0    	mov    %esi,0xf011852c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 85 11 f0    	mov    %ax,0xf0118528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 85 11 f0 	setne  0xf0118534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 b9 3d 10 f0       	push   $0xf0103db9
f01005f0:	e8 01 28 00 00       	call   f0102df6 <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	56                   	push   %esi
f010062f:	53                   	push   %ebx
f0100630:	bb a4 45 10 f0       	mov    $0xf01045a4,%ebx
f0100635:	be 04 46 10 f0       	mov    $0xf0104604,%esi
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010063a:	83 ec 04             	sub    $0x4,%esp
f010063d:	ff 33                	pushl  (%ebx)
f010063f:	ff 73 fc             	pushl  -0x4(%ebx)
f0100642:	68 00 40 10 f0       	push   $0xf0104000
f0100647:	e8 aa 27 00 00       	call   f0102df6 <cprintf>
f010064c:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
f010064f:	83 c4 10             	add    $0x10,%esp
f0100652:	39 f3                	cmp    %esi,%ebx
f0100654:	75 e4                	jne    f010063a <mon_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100656:	b8 00 00 00 00       	mov    $0x0,%eax
f010065b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010065e:	5b                   	pop    %ebx
f010065f:	5e                   	pop    %esi
f0100660:	5d                   	pop    %ebp
f0100661:	c3                   	ret    

f0100662 <mon_kerninfo>:


int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100662:	55                   	push   %ebp
f0100663:	89 e5                	mov    %esp,%ebp
f0100665:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100668:	68 09 40 10 f0       	push   $0xf0104009
f010066d:	e8 84 27 00 00       	call   f0102df6 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100672:	83 c4 08             	add    $0x8,%esp
f0100675:	68 0c 00 10 00       	push   $0x10000c
f010067a:	68 0c 42 10 f0       	push   $0xf010420c
f010067f:	e8 72 27 00 00       	call   f0102df6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100684:	83 c4 0c             	add    $0xc,%esp
f0100687:	68 0c 00 10 00       	push   $0x10000c
f010068c:	68 0c 00 10 f0       	push   $0xf010000c
f0100691:	68 34 42 10 f0       	push   $0xf0104234
f0100696:	e8 5b 27 00 00       	call   f0102df6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069b:	83 c4 0c             	add    $0xc,%esp
f010069e:	68 41 3d 10 00       	push   $0x103d41
f01006a3:	68 41 3d 10 f0       	push   $0xf0103d41
f01006a8:	68 58 42 10 f0       	push   $0xf0104258
f01006ad:	e8 44 27 00 00       	call   f0102df6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b2:	83 c4 0c             	add    $0xc,%esp
f01006b5:	68 00 83 11 00       	push   $0x118300
f01006ba:	68 00 83 11 f0       	push   $0xf0118300
f01006bf:	68 7c 42 10 f0       	push   $0xf010427c
f01006c4:	e8 2d 27 00 00       	call   f0102df6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006c9:	83 c4 0c             	add    $0xc,%esp
f01006cc:	68 60 89 11 00       	push   $0x118960
f01006d1:	68 60 89 11 f0       	push   $0xf0118960
f01006d6:	68 a0 42 10 f0       	push   $0xf01042a0
f01006db:	e8 16 27 00 00       	call   f0102df6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e0:	b8 5f 8d 11 f0       	mov    $0xf0118d5f,%eax
f01006e5:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006ea:	83 c4 08             	add    $0x8,%esp
f01006ed:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006f2:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006f8:	85 c0                	test   %eax,%eax
f01006fa:	0f 48 c2             	cmovs  %edx,%eax
f01006fd:	c1 f8 0a             	sar    $0xa,%eax
f0100700:	50                   	push   %eax
f0100701:	68 c4 42 10 f0       	push   $0xf01042c4
f0100706:	e8 eb 26 00 00       	call   f0102df6 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010070b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100710:	c9                   	leave  
f0100711:	c3                   	ret    

f0100712 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100712:	55                   	push   %ebp
f0100713:	89 e5                	mov    %esp,%ebp
f0100715:	57                   	push   %edi
f0100716:	56                   	push   %esi
f0100717:	53                   	push   %ebx
f0100718:	83 ec 38             	sub    $0x38,%esp
	// Your code here.
	cprintf("Stack backtrace:\n");
f010071b:	68 22 40 10 f0       	push   $0xf0104022
f0100720:	e8 d1 26 00 00       	call   f0102df6 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100725:	89 ee                	mov    %ebp,%esi
	int* ebp = ((int*)read_ebp());
	while (ebp != 0)
f0100727:	83 c4 10             	add    $0x10,%esp
	{
		int eip = *(ebp+1);
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",ebp+1,eip,*(ebp+2),*(ebp+3),*(ebp+4),*(ebp+5),*(ebp+6));
		struct Eipdebuginfo info;
		int tmp = debuginfo_eip(eip, &info);
f010072a:	8d 7d d0             	lea    -0x30(%ebp),%edi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	int* ebp = ((int*)read_ebp());
	while (ebp != 0)
f010072d:	eb 7d                	jmp    f01007ac <mon_backtrace+0x9a>
	{
		int eip = *(ebp+1);
f010072f:	8b 5e 04             	mov    0x4(%esi),%ebx
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",ebp+1,eip,*(ebp+2),*(ebp+3),*(ebp+4),*(ebp+5),*(ebp+6));
f0100732:	ff 76 18             	pushl  0x18(%esi)
f0100735:	ff 76 14             	pushl  0x14(%esi)
f0100738:	ff 76 10             	pushl  0x10(%esi)
f010073b:	ff 76 0c             	pushl  0xc(%esi)
f010073e:	ff 76 08             	pushl  0x8(%esi)
f0100741:	53                   	push   %ebx
f0100742:	8d 46 04             	lea    0x4(%esi),%eax
f0100745:	50                   	push   %eax
f0100746:	68 f0 42 10 f0       	push   $0xf01042f0
f010074b:	e8 a6 26 00 00       	call   f0102df6 <cprintf>
		struct Eipdebuginfo info;
		int tmp = debuginfo_eip(eip, &info);
f0100750:	83 c4 18             	add    $0x18,%esp
f0100753:	57                   	push   %edi
f0100754:	53                   	push   %ebx
f0100755:	e8 a6 27 00 00       	call   f0102f00 <debuginfo_eip>
		cprintf("         %s:%d: ",info.eip_file,info.eip_line);
f010075a:	83 c4 0c             	add    $0xc,%esp
f010075d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100760:	ff 75 d0             	pushl  -0x30(%ebp)
f0100763:	68 34 40 10 f0       	push   $0xf0104034
f0100768:	e8 89 26 00 00       	call   f0102df6 <cprintf>
		for (int i=0;i<info.eip_fn_namelen;i++)
f010076d:	83 c4 10             	add    $0x10,%esp
f0100770:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100775:	eb 1b                	jmp    f0100792 <mon_backtrace+0x80>
			cprintf("%c",info.eip_fn_name[i]);
f0100777:	83 ec 08             	sub    $0x8,%esp
f010077a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010077d:	0f be 04 18          	movsbl (%eax,%ebx,1),%eax
f0100781:	50                   	push   %eax
f0100782:	68 45 40 10 f0       	push   $0xf0104045
f0100787:	e8 6a 26 00 00       	call   f0102df6 <cprintf>
		int eip = *(ebp+1);
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",ebp+1,eip,*(ebp+2),*(ebp+3),*(ebp+4),*(ebp+5),*(ebp+6));
		struct Eipdebuginfo info;
		int tmp = debuginfo_eip(eip, &info);
		cprintf("         %s:%d: ",info.eip_file,info.eip_line);
		for (int i=0;i<info.eip_fn_namelen;i++)
f010078c:	83 c3 01             	add    $0x1,%ebx
f010078f:	83 c4 10             	add    $0x10,%esp
f0100792:	3b 5d dc             	cmp    -0x24(%ebp),%ebx
f0100795:	7c e0                	jl     f0100777 <mon_backtrace+0x65>
			cprintf("%c",info.eip_fn_name[i]);
		cprintf("+%d\n",info.eip_fn_narg);
f0100797:	83 ec 08             	sub    $0x8,%esp
f010079a:	ff 75 e4             	pushl  -0x1c(%ebp)
f010079d:	68 48 40 10 f0       	push   $0xf0104048
f01007a2:	e8 4f 26 00 00       	call   f0102df6 <cprintf>
		ebp = (int*)(*(ebp));
f01007a7:	8b 36                	mov    (%esi),%esi
f01007a9:	83 c4 10             	add    $0x10,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	int* ebp = ((int*)read_ebp());
	while (ebp != 0)
f01007ac:	85 f6                	test   %esi,%esi
f01007ae:	0f 85 7b ff ff ff    	jne    f010072f <mon_backtrace+0x1d>
		cprintf("+%d\n",info.eip_fn_narg);
		ebp = (int*)(*(ebp));
		
	}
	return 0;
}
f01007b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007bc:	5b                   	pop    %ebx
f01007bd:	5e                   	pop    %esi
f01007be:	5f                   	pop    %edi
f01007bf:	5d                   	pop    %ebp
f01007c0:	c3                   	ret    

f01007c1 <htoi>:
int htoi(char s[])  //translate from a hex string to int
{  
f01007c1:	55                   	push   %ebp
f01007c2:	89 e5                	mov    %esp,%ebp
f01007c4:	57                   	push   %edi
f01007c5:	56                   	push   %esi
f01007c6:	53                   	push   %ebx
f01007c7:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;  
	int n = 0;  
    if (s[0] == '0' && (s[1]=='x' || s[1]=='X')) i = 2;  
    else i = 0;  
f01007ca:	b9 00 00 00 00       	mov    $0x0,%ecx
}
int htoi(char s[])  //translate from a hex string to int
{  
	int i;  
	int n = 0;  
    if (s[0] == '0' && (s[1]=='x' || s[1]=='X')) i = 2;  
f01007cf:	80 38 30             	cmpb   $0x30,(%eax)
f01007d2:	75 12                	jne    f01007e6 <htoi+0x25>
f01007d4:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f01007d8:	83 e2 df             	and    $0xffffffdf,%edx
f01007db:	80 fa 58             	cmp    $0x58,%dl
f01007de:	0f 94 c1             	sete   %cl
f01007e1:	0f b6 c9             	movzbl %cl,%ecx
f01007e4:	01 c9                	add    %ecx,%ecx
f01007e6:	01 c1                	add    %eax,%ecx
    else i = 0;  
f01007e8:	bf 00 00 00 00       	mov    $0x0,%edi
f01007ed:	eb 38                	jmp    f0100827 <htoi+0x66>
    for (; (s[i] >= '0' && s[i] <= '9') || (s[i] >= 'a' && s[i] <= 'z') || (s[i] >='A' && s[i] <= 'F');++i)  
        if ('a' <= s[i] && s[i] <='f')   
f01007ef:	80 fb 05             	cmp    $0x5,%bl
f01007f2:	77 0e                	ja     f0100802 <htoi+0x41>
            n = n * 16 + 10 + s[i] - 'a';
f01007f4:	89 f8                	mov    %edi,%eax
f01007f6:	c1 e0 04             	shl    $0x4,%eax
f01007f9:	0f be d2             	movsbl %dl,%edx
f01007fc:	8d 7c 10 a9          	lea    -0x57(%eax,%edx,1),%edi
f0100800:	eb 22                	jmp    f0100824 <htoi+0x63>
        else if ('A' <= s[i] && s[i] <= 'F')
f0100802:	8d 5a bf             	lea    -0x41(%edx),%ebx
f0100805:	80 fb 05             	cmp    $0x5,%bl
f0100808:	77 0e                	ja     f0100818 <htoi+0x57>
        	n = n * 16+s[i]+10-'A';    
f010080a:	89 f8                	mov    %edi,%eax
f010080c:	c1 e0 04             	shl    $0x4,%eax
f010080f:	0f be d2             	movsbl %dl,%edx
f0100812:	8d 7c 10 c9          	lea    -0x37(%eax,%edx,1),%edi
f0100816:	eb 0c                	jmp    f0100824 <htoi+0x63>
        else   
            n = n * 16 + (s[i] - '0');  
f0100818:	89 f8                	mov    %edi,%eax
f010081a:	c1 e0 04             	shl    $0x4,%eax
f010081d:	0f be d2             	movsbl %dl,%edx
f0100820:	8d 7c 10 d0          	lea    -0x30(%eax,%edx,1),%edi
f0100824:	83 c1 01             	add    $0x1,%ecx
{  
	int i;  
	int n = 0;  
    if (s[0] == '0' && (s[1]=='x' || s[1]=='X')) i = 2;  
    else i = 0;  
    for (; (s[i] >= '0' && s[i] <= '9') || (s[i] >= 'a' && s[i] <= 'z') || (s[i] >='A' && s[i] <= 'F');++i)  
f0100827:	0f b6 11             	movzbl (%ecx),%edx
f010082a:	8d 5a 9f             	lea    -0x61(%edx),%ebx
f010082d:	8d 72 d0             	lea    -0x30(%edx),%esi
f0100830:	89 f0                	mov    %esi,%eax
f0100832:	3c 09                	cmp    $0x9,%al
f0100834:	76 b9                	jbe    f01007ef <htoi+0x2e>
f0100836:	80 fb 19             	cmp    $0x19,%bl
f0100839:	76 b4                	jbe    f01007ef <htoi+0x2e>
f010083b:	8d 72 bf             	lea    -0x41(%edx),%esi
f010083e:	89 f0                	mov    %esi,%eax
f0100840:	3c 05                	cmp    $0x5,%al
f0100842:	77 07                	ja     f010084b <htoi+0x8a>
        if ('a' <= s[i] && s[i] <='f')   
f0100844:	80 fb 05             	cmp    $0x5,%bl
f0100847:	76 ab                	jbe    f01007f4 <htoi+0x33>
f0100849:	eb bf                	jmp    f010080a <htoi+0x49>
        else if ('A' <= s[i] && s[i] <= 'F')
        	n = n * 16+s[i]+10-'A';    
        else   
            n = n * 16 + (s[i] - '0');  
    return n;  
}  
f010084b:	89 f8                	mov    %edi,%eax
f010084d:	5b                   	pop    %ebx
f010084e:	5e                   	pop    %esi
f010084f:	5f                   	pop    %edi
f0100850:	5d                   	pop    %ebp
f0100851:	c3                   	ret    

f0100852 <mon_showmapping>:
//showmemorymapping
int mon_showmapping(int argc, char **argv, struct Trapframe *tf)
{
f0100852:	55                   	push   %ebp
f0100853:	89 e5                	mov    %esp,%ebp
f0100855:	56                   	push   %esi
f0100856:	53                   	push   %ebx
f0100857:	8b 75 0c             	mov    0xc(%ebp),%esi
	//cprintf("%d\n",argc);
	if (argc != 3)
f010085a:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f010085e:	74 15                	je     f0100875 <mon_showmapping+0x23>
	{
		cprintf("you should give 2 arguments l and r\n");
f0100860:	83 ec 0c             	sub    $0xc,%esp
f0100863:	68 28 43 10 f0       	push   $0xf0104328
f0100868:	e8 89 25 00 00       	call   f0102df6 <cprintf>
		return 0;
f010086d:	83 c4 10             	add    $0x10,%esp
f0100870:	e9 c0 00 00 00       	jmp    f0100935 <mon_showmapping+0xe3>
	}
	size_t l,r;
	l = htoi(argv[1]);
f0100875:	83 ec 0c             	sub    $0xc,%esp
f0100878:	ff 76 04             	pushl  0x4(%esi)
f010087b:	e8 41 ff ff ff       	call   f01007c1 <htoi>
f0100880:	83 c4 04             	add    $0x4,%esp
f0100883:	89 c3                	mov    %eax,%ebx
	r = htoi(argv[2]);
f0100885:	ff 76 08             	pushl  0x8(%esi)
f0100888:	e8 34 ff ff ff       	call   f01007c1 <htoi>
f010088d:	83 c4 10             	add    $0x10,%esp
f0100890:	89 c6                	mov    %eax,%esi
	if (l % PGSIZE != 0 || r % PGSIZE != 0)
f0100892:	89 d8                	mov    %ebx,%eax
f0100894:	09 f0                	or     %esi,%eax
f0100896:	a9 ff 0f 00 00       	test   $0xfff,%eax
f010089b:	74 15                	je     f01008b2 <mon_showmapping+0x60>
	{
		cprintf("invalid l or r\n");
f010089d:	83 ec 0c             	sub    $0xc,%esp
f01008a0:	68 4d 40 10 f0       	push   $0xf010404d
f01008a5:	e8 4c 25 00 00       	call   f0102df6 <cprintf>
		return 0;
f01008aa:	83 c4 10             	add    $0x10,%esp
f01008ad:	e9 83 00 00 00       	jmp    f0100935 <mon_showmapping+0xe3>
	}
	cprintf("VM          PM      PTE_P  PTE_W  PTE_U\n");
f01008b2:	83 ec 0c             	sub    $0xc,%esp
f01008b5:	68 50 43 10 f0       	push   $0xf0104350
f01008ba:	e8 37 25 00 00       	call   f0102df6 <cprintf>
	for (size_t i = l;i<=r;i+=PGSIZE)
f01008bf:	83 c4 10             	add    $0x10,%esp
f01008c2:	eb 6d                	jmp    f0100931 <mon_showmapping+0xdf>
	{
		cprintf("%8x  ",i);
f01008c4:	83 ec 08             	sub    $0x8,%esp
f01008c7:	53                   	push   %ebx
f01008c8:	68 5d 40 10 f0       	push   $0xf010405d
f01008cd:	e8 24 25 00 00       	call   f0102df6 <cprintf>
		pte_t* pte = pgdir_walk(kern_pgdir,(char*)i,0);
f01008d2:	83 c4 0c             	add    $0xc,%esp
f01008d5:	6a 00                	push   $0x0
f01008d7:	53                   	push   %ebx
f01008d8:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f01008de:	e8 2a 0c 00 00       	call   f010150d <pgdir_walk>
		if (pte == NULL) 
f01008e3:	83 c4 10             	add    $0x10,%esp
f01008e6:	85 c0                	test   %eax,%eax
f01008e8:	75 12                	jne    f01008fc <mon_showmapping+0xaa>
		{
			cprintf("No mapping\n");
f01008ea:	83 ec 0c             	sub    $0xc,%esp
f01008ed:	68 63 40 10 f0       	push   $0xf0104063
f01008f2:	e8 ff 24 00 00       	call   f0102df6 <cprintf>
			continue;
f01008f7:	83 c4 10             	add    $0x10,%esp
f01008fa:	eb 2f                	jmp    f010092b <mon_showmapping+0xd9>
		}
		physaddr_t pa = *pte;
f01008fc:	8b 00                	mov    (%eax),%eax
		cprintf("%8x  %d      %d      %d\n",(pa>>12)<<12,pa&PTE_P,(pa&PTE_W)>>1,(pa&PTE_U)>>2);
f01008fe:	83 ec 0c             	sub    $0xc,%esp
f0100901:	89 c2                	mov    %eax,%edx
f0100903:	83 e2 04             	and    $0x4,%edx
f0100906:	c1 ea 02             	shr    $0x2,%edx
f0100909:	52                   	push   %edx
f010090a:	89 c2                	mov    %eax,%edx
f010090c:	83 e2 02             	and    $0x2,%edx
f010090f:	d1 ea                	shr    %edx
f0100911:	52                   	push   %edx
f0100912:	89 c2                	mov    %eax,%edx
f0100914:	83 e2 01             	and    $0x1,%edx
f0100917:	52                   	push   %edx
f0100918:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010091d:	50                   	push   %eax
f010091e:	68 d9 40 10 f0       	push   $0xf01040d9
f0100923:	e8 ce 24 00 00       	call   f0102df6 <cprintf>
f0100928:	83 c4 20             	add    $0x20,%esp
	{
		cprintf("invalid l or r\n");
		return 0;
	}
	cprintf("VM          PM      PTE_P  PTE_W  PTE_U\n");
	for (size_t i = l;i<=r;i+=PGSIZE)
f010092b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100931:	39 f3                	cmp    %esi,%ebx
f0100933:	76 8f                	jbe    f01008c4 <mon_showmapping+0x72>
		}
		physaddr_t pa = *pte;
		cprintf("%8x  %d      %d      %d\n",(pa>>12)<<12,pa&PTE_P,(pa&PTE_W)>>1,(pa&PTE_U)>>2);
	}
	return 0;
}
f0100935:	b8 00 00 00 00       	mov    $0x0,%eax
f010093a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010093d:	5b                   	pop    %ebx
f010093e:	5e                   	pop    %esi
f010093f:	5d                   	pop    %ebp
f0100940:	c3                   	ret    

f0100941 <mon_setmappingperm>:
//set any permision of any pte via va.
int mon_setmappingperm(int argc, char **argv, struct Trapframe *tf)
{
f0100941:	55                   	push   %ebp
f0100942:	89 e5                	mov    %esp,%ebp
f0100944:	57                   	push   %edi
f0100945:	56                   	push   %esi
f0100946:	53                   	push   %ebx
f0100947:	83 ec 1c             	sub    $0x1c,%esp
f010094a:	8b 55 0c             	mov    0xc(%ebp),%edx
	if (argc != 4)
f010094d:	83 7d 08 04          	cmpl   $0x4,0x8(%ebp)
f0100951:	74 15                	je     f0100968 <mon_setmappingperm+0x27>
	{
		cprintf("Wrong argument number.\n");
f0100953:	83 ec 0c             	sub    $0xc,%esp
f0100956:	68 6f 40 10 f0       	push   $0xf010406f
f010095b:	e8 96 24 00 00       	call   f0102df6 <cprintf>
		return 0;
f0100960:	83 c4 10             	add    $0x10,%esp
f0100963:	e9 01 01 00 00       	jmp    f0100a69 <mon_setmappingperm+0x128>
	}
	int b = argv[3][0]-'0';
	int a = argv[2][0];
f0100968:	8b 42 08             	mov    0x8(%edx),%eax
f010096b:	0f b6 00             	movzbl (%eax),%eax
f010096e:	0f be f0             	movsbl %al,%esi
	if ((a!='P' && a!='U' && a!='W') || (b!=0 && b!=1))
f0100971:	83 e0 fd             	and    $0xfffffffd,%eax
f0100974:	3c 55                	cmp    $0x55,%al
f0100976:	74 05                	je     f010097d <mon_setmappingperm+0x3c>
f0100978:	83 fe 50             	cmp    $0x50,%esi
f010097b:	75 0e                	jne    f010098b <mon_setmappingperm+0x4a>
	if (argc != 4)
	{
		cprintf("Wrong argument number.\n");
		return 0;
	}
	int b = argv[3][0]-'0';
f010097d:	8b 42 0c             	mov    0xc(%edx),%eax
f0100980:	0f be 18             	movsbl (%eax),%ebx
f0100983:	83 eb 30             	sub    $0x30,%ebx
	int a = argv[2][0];
	if ((a!='P' && a!='U' && a!='W') || (b!=0 && b!=1))
f0100986:	83 fb 01             	cmp    $0x1,%ebx
f0100989:	76 15                	jbe    f01009a0 <mon_setmappingperm+0x5f>
	{
		cprintf("Invalid input.\n");
f010098b:	83 ec 0c             	sub    $0xc,%esp
f010098e:	68 87 40 10 f0       	push   $0xf0104087
f0100993:	e8 5e 24 00 00       	call   f0102df6 <cprintf>
		return 0;
f0100998:	83 c4 10             	add    $0x10,%esp
f010099b:	e9 c9 00 00 00       	jmp    f0100a69 <mon_setmappingperm+0x128>
	}
	uintptr_t va = htoi(argv[1]);
f01009a0:	83 ec 0c             	sub    $0xc,%esp
f01009a3:	ff 72 04             	pushl  0x4(%edx)
f01009a6:	e8 16 fe ff ff       	call   f01007c1 <htoi>
f01009ab:	83 c4 10             	add    $0x10,%esp
f01009ae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (va % PGSIZE != 0)
f01009b1:	a9 ff 0f 00 00       	test   $0xfff,%eax
f01009b6:	74 15                	je     f01009cd <mon_setmappingperm+0x8c>
	{
		cprintf("va not aligned.\n");
f01009b8:	83 ec 0c             	sub    $0xc,%esp
f01009bb:	68 97 40 10 f0       	push   $0xf0104097
f01009c0:	e8 31 24 00 00       	call   f0102df6 <cprintf>
		return 0;
f01009c5:	83 c4 10             	add    $0x10,%esp
f01009c8:	e9 9c 00 00 00       	jmp    f0100a69 <mon_setmappingperm+0x128>
	}
	pte_t *pte = pgdir_walk(kern_pgdir,(char*)va,0);
f01009cd:	83 ec 04             	sub    $0x4,%esp
f01009d0:	6a 00                	push   $0x0
f01009d2:	ff 75 e4             	pushl  -0x1c(%ebp)
f01009d5:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f01009db:	e8 2d 0b 00 00       	call   f010150d <pgdir_walk>
f01009e0:	89 c7                	mov    %eax,%edi
	if (pte == NULL)
f01009e2:	83 c4 10             	add    $0x10,%esp
f01009e5:	85 c0                	test   %eax,%eax
f01009e7:	75 12                	jne    f01009fb <mon_setmappingperm+0xba>
	{
		cprintf("This va has not been mapped.\n");
f01009e9:	83 ec 0c             	sub    $0xc,%esp
f01009ec:	68 a8 40 10 f0       	push   $0xf01040a8
f01009f1:	e8 00 24 00 00       	call   f0102df6 <cprintf>
		return 0;
f01009f6:	83 c4 10             	add    $0x10,%esp
f01009f9:	eb 6e                	jmp    f0100a69 <mon_setmappingperm+0x128>
	}
	unsigned int perm;
	if (a=='P') perm=PTE_P;
	if (a=='U') perm=PTE_U;
f01009fb:	b8 04 00 00 00       	mov    $0x4,%eax
f0100a00:	83 fe 55             	cmp    $0x55,%esi
f0100a03:	74 0c                	je     f0100a11 <mon_setmappingperm+0xd0>
	if (a=='W') perm=PTE_W;
f0100a05:	83 fe 57             	cmp    $0x57,%esi
f0100a08:	0f 94 c0             	sete   %al
f0100a0b:	0f b6 c0             	movzbl %al,%eax
f0100a0e:	83 c0 01             	add    $0x1,%eax
	if (b==0) (*pte)&=~perm;
f0100a11:	85 db                	test   %ebx,%ebx
f0100a13:	75 06                	jne    f0100a1b <mon_setmappingperm+0xda>
f0100a15:	f7 d0                	not    %eax
f0100a17:	21 07                	and    %eax,(%edi)
f0100a19:	eb 02                	jmp    f0100a1d <mon_setmappingperm+0xdc>
	else (*pte)|=perm;
f0100a1b:	09 07                	or     %eax,(%edi)
	cprintf("Set succeed.\n");
f0100a1d:	83 ec 0c             	sub    $0xc,%esp
f0100a20:	68 c6 40 10 f0       	push   $0xf01040c6
f0100a25:	e8 cc 23 00 00       	call   f0102df6 <cprintf>
	physaddr_t pa = *pte;
f0100a2a:	8b 1f                	mov    (%edi),%ebx
	cprintf("VM          PM      PTE_P  PTE_W  PTE_U\n");
f0100a2c:	c7 04 24 50 43 10 f0 	movl   $0xf0104350,(%esp)
f0100a33:	e8 be 23 00 00       	call   f0102df6 <cprintf>
	cprintf("%8x  %8x  %d      %d      %d\n",va,(pa>>12)<<12,pa&PTE_P,(pa&PTE_W)>>1,(pa&PTE_U)>>2);
f0100a38:	83 c4 08             	add    $0x8,%esp
f0100a3b:	89 d8                	mov    %ebx,%eax
f0100a3d:	83 e0 04             	and    $0x4,%eax
f0100a40:	c1 e8 02             	shr    $0x2,%eax
f0100a43:	50                   	push   %eax
f0100a44:	89 d8                	mov    %ebx,%eax
f0100a46:	83 e0 02             	and    $0x2,%eax
f0100a49:	d1 e8                	shr    %eax
f0100a4b:	50                   	push   %eax
f0100a4c:	89 d8                	mov    %ebx,%eax
f0100a4e:	83 e0 01             	and    $0x1,%eax
f0100a51:	50                   	push   %eax
f0100a52:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0100a58:	53                   	push   %ebx
f0100a59:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100a5c:	68 d4 40 10 f0       	push   $0xf01040d4
f0100a61:	e8 90 23 00 00       	call   f0102df6 <cprintf>
	return 0;
f0100a66:	83 c4 20             	add    $0x20,%esp
}
f0100a69:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a6e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a71:	5b                   	pop    %ebx
f0100a72:	5e                   	pop    %esi
f0100a73:	5f                   	pop    %edi
f0100a74:	5d                   	pop    %ebp
f0100a75:	c3                   	ret    

f0100a76 <mon_vdump>:

int mon_vdump(int argc, char **argv, struct Trapframe *tf)
{
f0100a76:	55                   	push   %ebp
f0100a77:	89 e5                	mov    %esp,%ebp
f0100a79:	57                   	push   %edi
f0100a7a:	56                   	push   %esi
f0100a7b:	53                   	push   %ebx
f0100a7c:	83 ec 1c             	sub    $0x1c,%esp
f0100a7f:	8b 7d 0c             	mov    0xc(%ebp),%edi
	//What I do is check every byte to see whether it is available.
	if (argc != 4)
f0100a82:	83 7d 08 04          	cmpl   $0x4,0x8(%ebp)
f0100a86:	74 15                	je     f0100a9d <mon_vdump+0x27>
	{
		cprintf("Wrong argument number.\n");
f0100a88:	83 ec 0c             	sub    $0xc,%esp
f0100a8b:	68 6f 40 10 f0       	push   $0xf010406f
f0100a90:	e8 61 23 00 00       	call   f0102df6 <cprintf>
		return 0;
f0100a95:	83 c4 10             	add    $0x10,%esp
f0100a98:	e9 7e 01 00 00       	jmp    f0100c1b <mon_vdump+0x1a5>
	}
	uintptr_t va1 = htoi(argv[1]);
f0100a9d:	83 ec 0c             	sub    $0xc,%esp
f0100aa0:	ff 77 04             	pushl  0x4(%edi)
f0100aa3:	e8 19 fd ff ff       	call   f01007c1 <htoi>
f0100aa8:	83 c4 04             	add    $0x4,%esp
f0100aab:	89 c6                	mov    %eax,%esi
	uintptr_t va2 = htoi(argv[2]);
f0100aad:	ff 77 08             	pushl  0x8(%edi)
f0100ab0:	e8 0c fd ff ff       	call   f01007c1 <htoi>
f0100ab5:	83 c4 04             	add    $0x4,%esp
f0100ab8:	89 c3                	mov    %eax,%ebx
	size_t size = htoi(argv[3]);
f0100aba:	ff 77 0c             	pushl  0xc(%edi)
f0100abd:	e8 ff fc ff ff       	call   f01007c1 <htoi>
f0100ac2:	83 c4 10             	add    $0x10,%esp
	if (va1 + size > KERNBASE+npages*PGSIZE || va2 + size > KERNBASE+npages*PGSIZE || va1<KERNBASE || va2<KERNBASE)
f0100ac5:	8d 3c 06             	lea    (%esi,%eax,1),%edi
f0100ac8:	89 7d dc             	mov    %edi,-0x24(%ebp)
f0100acb:	8b 15 68 89 11 f0    	mov    0xf0118968,%edx
f0100ad1:	81 c2 00 00 0f 00    	add    $0xf0000,%edx
f0100ad7:	c1 e2 0c             	shl    $0xc,%edx
f0100ada:	39 d7                	cmp    %edx,%edi
f0100adc:	77 1e                	ja     f0100afc <mon_vdump+0x86>
f0100ade:	01 d8                	add    %ebx,%eax
f0100ae0:	39 c2                	cmp    %eax,%edx
f0100ae2:	72 18                	jb     f0100afc <mon_vdump+0x86>
f0100ae4:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0100aea:	76 10                	jbe    f0100afc <mon_vdump+0x86>
f0100aec:	89 f7                	mov    %esi,%edi
f0100aee:	89 de                	mov    %ebx,%esi
f0100af0:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0100af6:	0f 87 06 01 00 00    	ja     f0100c02 <mon_vdump+0x18c>
	{
		cprintf("Invalid virturall address\n");
f0100afc:	83 ec 0c             	sub    $0xc,%esp
f0100aff:	68 f2 40 10 f0       	push   $0xf01040f2
f0100b04:	e8 ed 22 00 00       	call   f0102df6 <cprintf>
		return 0;
f0100b09:	83 c4 10             	add    $0x10,%esp
f0100b0c:	e9 0a 01 00 00       	jmp    f0100c1b <mon_vdump+0x1a5>
	}
	for (size_t i=0;i<size;i++)
	{
		pte_t* pte1 = pgdir_walk(kern_pgdir,(char*)(va1+i),0);
f0100b11:	83 ec 04             	sub    $0x4,%esp
f0100b14:	6a 00                	push   $0x0
f0100b16:	57                   	push   %edi
f0100b17:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0100b1d:	e8 eb 09 00 00       	call   f010150d <pgdir_walk>
f0100b22:	89 c3                	mov    %eax,%ebx
		if (pte1==NULL || !((*pte1)&PTE_P))
f0100b24:	83 c4 10             	add    $0x10,%esp
f0100b27:	85 c0                	test   %eax,%eax
f0100b29:	74 05                	je     f0100b30 <mon_vdump+0xba>
f0100b2b:	f6 00 01             	testb  $0x1,(%eax)
f0100b2e:	75 16                	jne    f0100b46 <mon_vdump+0xd0>
		{
			cprintf("Source address can't read at %p.\n",va1+i);
f0100b30:	83 ec 08             	sub    $0x8,%esp
f0100b33:	57                   	push   %edi
f0100b34:	68 7c 43 10 f0       	push   $0xf010437c
f0100b39:	e8 b8 22 00 00       	call   f0102df6 <cprintf>
			return 0;
f0100b3e:	83 c4 10             	add    $0x10,%esp
f0100b41:	e9 d5 00 00 00       	jmp    f0100c1b <mon_vdump+0x1a5>
		}
		pte_t* pte2 = pgdir_walk(kern_pgdir,(char*)(va2+i),1);
f0100b46:	83 ec 04             	sub    $0x4,%esp
f0100b49:	6a 01                	push   $0x1
f0100b4b:	56                   	push   %esi
f0100b4c:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0100b52:	e8 b6 09 00 00       	call   f010150d <pgdir_walk>
		if (pte2==NULL || (!((*pte2) & PTE_P) || !((*pte2) & PTE_W)))
f0100b57:	83 c4 10             	add    $0x10,%esp
f0100b5a:	85 c0                	test   %eax,%eax
f0100b5c:	74 0c                	je     f0100b6a <mon_vdump+0xf4>
f0100b5e:	8b 00                	mov    (%eax),%eax
f0100b60:	89 c2                	mov    %eax,%edx
f0100b62:	83 e2 03             	and    $0x3,%edx
f0100b65:	83 fa 03             	cmp    $0x3,%edx
f0100b68:	74 16                	je     f0100b80 <mon_vdump+0x10a>
		{
			cprintf("Purpose address can't write at %p.\n",va2+i);
f0100b6a:	83 ec 08             	sub    $0x8,%esp
f0100b6d:	56                   	push   %esi
f0100b6e:	68 a0 43 10 f0       	push   $0xf01043a0
f0100b73:	e8 7e 22 00 00       	call   f0102df6 <cprintf>
			return 0;
f0100b78:	83 c4 10             	add    $0x10,%esp
f0100b7b:	e9 9b 00 00 00       	jmp    f0100c1b <mon_vdump+0x1a5>
		}
		size_t offset1 = (va1+i)%PGSIZE;
f0100b80:	89 f9                	mov    %edi,%ecx
f0100b82:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
f0100b88:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		size_t offset2 = (va2+i)%PGSIZE;
f0100b8b:	89 f2                	mov    %esi,%edx
f0100b8d:	81 e2 ff 0f 00 00    	and    $0xfff,%edx
		*((char*)KADDR(PTE_ADDR(*pte2)) + offset2) = *((char*)KADDR(PTE_ADDR(*pte1)) + offset1);
f0100b93:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b98:	8b 0d 68 89 11 f0    	mov    0xf0118968,%ecx
f0100b9e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100ba1:	89 c1                	mov    %eax,%ecx
f0100ba3:	c1 e9 0c             	shr    $0xc,%ecx
f0100ba6:	3b 4d e4             	cmp    -0x1c(%ebp),%ecx
f0100ba9:	72 15                	jb     f0100bc0 <mon_vdump+0x14a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bab:	50                   	push   %eax
f0100bac:	68 c4 43 10 f0       	push   $0xf01043c4
f0100bb1:	68 cd 00 00 00       	push   $0xcd
f0100bb6:	68 0d 41 10 f0       	push   $0xf010410d
f0100bbb:	e8 cb f4 ff ff       	call   f010008b <_panic>
f0100bc0:	8d 94 02 00 00 00 f0 	lea    -0x10000000(%edx,%eax,1),%edx
f0100bc7:	8b 03                	mov    (%ebx),%eax
f0100bc9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bce:	83 c7 01             	add    $0x1,%edi
f0100bd1:	83 c6 01             	add    $0x1,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bd4:	89 c1                	mov    %eax,%ecx
f0100bd6:	c1 e9 0c             	shr    $0xc,%ecx
f0100bd9:	3b 4d e4             	cmp    -0x1c(%ebp),%ecx
f0100bdc:	72 15                	jb     f0100bf3 <mon_vdump+0x17d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bde:	50                   	push   %eax
f0100bdf:	68 c4 43 10 f0       	push   $0xf01043c4
f0100be4:	68 cd 00 00 00       	push   $0xcd
f0100be9:	68 0d 41 10 f0       	push   $0xf010410d
f0100bee:	e8 98 f4 ff ff       	call   f010008b <_panic>
f0100bf3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100bf6:	0f b6 84 03 00 00 00 	movzbl -0x10000000(%ebx,%eax,1),%eax
f0100bfd:	f0 
f0100bfe:	88 02                	mov    %al,(%edx)
f0100c00:	eb 00                	jmp    f0100c02 <mon_vdump+0x18c>
	if (va1 + size > KERNBASE+npages*PGSIZE || va2 + size > KERNBASE+npages*PGSIZE || va1<KERNBASE || va2<KERNBASE)
	{
		cprintf("Invalid virturall address\n");
		return 0;
	}
	for (size_t i=0;i<size;i++)
f0100c02:	39 7d dc             	cmp    %edi,-0x24(%ebp)
f0100c05:	0f 85 06 ff ff ff    	jne    f0100b11 <mon_vdump+0x9b>
		}
		size_t offset1 = (va1+i)%PGSIZE;
		size_t offset2 = (va2+i)%PGSIZE;
		*((char*)KADDR(PTE_ADDR(*pte2)) + offset2) = *((char*)KADDR(PTE_ADDR(*pte1)) + offset1);
	}
	cprintf("Succeed.\n");
f0100c0b:	83 ec 0c             	sub    $0xc,%esp
f0100c0e:	68 1c 41 10 f0       	push   $0xf010411c
f0100c13:	e8 de 21 00 00       	call   f0102df6 <cprintf>
	return 0;
f0100c18:	83 c4 10             	add    $0x10,%esp
}
f0100c1b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c20:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c23:	5b                   	pop    %ebx
f0100c24:	5e                   	pop    %esi
f0100c25:	5f                   	pop    %edi
f0100c26:	5d                   	pop    %ebp
f0100c27:	c3                   	ret    

f0100c28 <mon_pdump>:
int mon_pdump(int argc, char **argv, struct Trapframe *tf)
{
f0100c28:	55                   	push   %ebp
f0100c29:	89 e5                	mov    %esp,%ebp
f0100c2b:	57                   	push   %edi
f0100c2c:	56                   	push   %esi
f0100c2d:	53                   	push   %ebx
f0100c2e:	83 ec 1c             	sub    $0x1c,%esp
f0100c31:	8b 75 0c             	mov    0xc(%ebp),%esi
	if (argc != 4)
f0100c34:	83 7d 08 04          	cmpl   $0x4,0x8(%ebp)
f0100c38:	74 15                	je     f0100c4f <mon_pdump+0x27>
	{
		cprintf("Wrong argument number.\n");
f0100c3a:	83 ec 0c             	sub    $0xc,%esp
f0100c3d:	68 6f 40 10 f0       	push   $0xf010406f
f0100c42:	e8 af 21 00 00       	call   f0102df6 <cprintf>
		return 0;
f0100c47:	83 c4 10             	add    $0x10,%esp
f0100c4a:	e9 bb 00 00 00       	jmp    f0100d0a <mon_pdump+0xe2>
	}
	physaddr_t pa1 = htoi(argv[1]);
f0100c4f:	83 ec 0c             	sub    $0xc,%esp
f0100c52:	ff 76 04             	pushl  0x4(%esi)
f0100c55:	e8 67 fb ff ff       	call   f01007c1 <htoi>
f0100c5a:	83 c4 04             	add    $0x4,%esp
f0100c5d:	89 c3                	mov    %eax,%ebx
	physaddr_t pa2 = htoi(argv[2]);
f0100c5f:	ff 76 08             	pushl  0x8(%esi)
f0100c62:	e8 5a fb ff ff       	call   f01007c1 <htoi>
f0100c67:	83 c4 04             	add    $0x4,%esp
f0100c6a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	size_t size = htoi(argv[3]);
f0100c6d:	ff 76 0c             	pushl  0xc(%esi)
f0100c70:	e8 4c fb ff ff       	call   f01007c1 <htoi>
f0100c75:	83 c4 10             	add    $0x10,%esp
f0100c78:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if (pa1 + size > 0xffffffff || pa2 + size > 0xffffffff || pa1<0 || pa2<0)
	{
		cprintf("Invalid physical address\n");
		return 0;
	}
	for (size_t i=0;i<size;i+=PGSIZE)
f0100c7b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c80:	eb 73                	jmp    f0100cf5 <mon_pdump+0xcd>
f0100c82:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c85:	8b 35 68 89 11 f0    	mov    0xf0118968,%esi
f0100c8b:	89 d0                	mov    %edx,%eax
f0100c8d:	c1 e8 0c             	shr    $0xc,%eax
f0100c90:	39 f0                	cmp    %esi,%eax
f0100c92:	72 15                	jb     f0100ca9 <mon_pdump+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c94:	52                   	push   %edx
f0100c95:	68 c4 43 10 f0       	push   $0xf01043c4
f0100c9a:	68 e3 00 00 00       	push   $0xe3
f0100c9f:	68 0d 41 10 f0       	push   $0xf010410d
f0100ca4:	e8 e2 f3 ff ff       	call   f010008b <_panic>
f0100ca9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cac:	01 c8                	add    %ecx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cae:	89 c7                	mov    %eax,%edi
f0100cb0:	c1 ef 0c             	shr    $0xc,%edi
f0100cb3:	39 f7                	cmp    %esi,%edi
f0100cb5:	72 15                	jb     f0100ccc <mon_pdump+0xa4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cb7:	50                   	push   %eax
f0100cb8:	68 c4 43 10 f0       	push   $0xf01043c4
f0100cbd:	68 e4 00 00 00       	push   $0xe4
f0100cc2:	68 0d 41 10 f0       	push   $0xf010410d
f0100cc7:	e8 bf f3 ff ff       	call   f010008b <_panic>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ccc:	be 00 00 00 00       	mov    $0x0,%esi
f0100cd1:	89 cf                	mov    %ecx,%edi
	{
		char* va1 = KADDR(pa1+i); //there has implemented panic in KADDR so I will not check.
		char* va2 = KADDR(pa2+i);
		for (size_t j=0;j<PGSIZE;j++)
			*(va2+j) = *(va1+j);
f0100cd3:	0f b6 8c 16 00 00 00 	movzbl -0x10000000(%esi,%edx,1),%ecx
f0100cda:	f0 
f0100cdb:	88 8c 06 00 00 00 f0 	mov    %cl,-0x10000000(%esi,%eax,1)
	}
	for (size_t i=0;i<size;i+=PGSIZE)
	{
		char* va1 = KADDR(pa1+i); //there has implemented panic in KADDR so I will not check.
		char* va2 = KADDR(pa2+i);
		for (size_t j=0;j<PGSIZE;j++)
f0100ce2:	83 c6 01             	add    $0x1,%esi
f0100ce5:	81 fe 00 10 00 00    	cmp    $0x1000,%esi
f0100ceb:	75 e6                	jne    f0100cd3 <mon_pdump+0xab>
f0100ced:	89 f9                	mov    %edi,%ecx
	if (pa1 + size > 0xffffffff || pa2 + size > 0xffffffff || pa1<0 || pa2<0)
	{
		cprintf("Invalid physical address\n");
		return 0;
	}
	for (size_t i=0;i<size;i+=PGSIZE)
f0100cef:	81 c1 00 10 00 00    	add    $0x1000,%ecx
f0100cf5:	3b 4d e0             	cmp    -0x20(%ebp),%ecx
f0100cf8:	72 88                	jb     f0100c82 <mon_pdump+0x5a>
		char* va1 = KADDR(pa1+i); //there has implemented panic in KADDR so I will not check.
		char* va2 = KADDR(pa2+i);
		for (size_t j=0;j<PGSIZE;j++)
			*(va2+j) = *(va1+j);
	}
	cprintf("Succeed.\n");
f0100cfa:	83 ec 0c             	sub    $0xc,%esp
f0100cfd:	68 1c 41 10 f0       	push   $0xf010411c
f0100d02:	e8 ef 20 00 00       	call   f0102df6 <cprintf>
	return 0;
f0100d07:	83 c4 10             	add    $0x10,%esp
}
f0100d0a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d0f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d12:	5b                   	pop    %ebx
f0100d13:	5e                   	pop    %esi
f0100d14:	5f                   	pop    %edi
f0100d15:	5d                   	pop    %ebp
f0100d16:	c3                   	ret    

f0100d17 <mon_showmemory>:
int mon_showmemory(int argc,char **argv,struct Trapframe *tf)
{
f0100d17:	55                   	push   %ebp
f0100d18:	89 e5                	mov    %esp,%ebp
f0100d1a:	53                   	push   %ebx
f0100d1b:	83 ec 04             	sub    $0x4,%esp
	if (argc != 2)
f0100d1e:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
f0100d22:	74 15                	je     f0100d39 <mon_showmemory+0x22>
	{
		cprintf("Wrong argument number.\n");
f0100d24:	83 ec 0c             	sub    $0xc,%esp
f0100d27:	68 6f 40 10 f0       	push   $0xf010406f
f0100d2c:	e8 c5 20 00 00       	call   f0102df6 <cprintf>
		return 0;
f0100d31:	83 c4 10             	add    $0x10,%esp
f0100d34:	e9 ff 00 00 00       	jmp    f0100e38 <mon_showmemory+0x121>
	}
	uintptr_t va = htoi(argv[1]);
f0100d39:	83 ec 0c             	sub    $0xc,%esp
f0100d3c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d3f:	ff 70 04             	pushl  0x4(%eax)
f0100d42:	e8 7a fa ff ff       	call   f01007c1 <htoi>
f0100d47:	83 c4 10             	add    $0x10,%esp
f0100d4a:	89 c3                	mov    %eax,%ebx
	if (va > KERNBASE+npages*PGSIZE || va<KERNBASE )
f0100d4c:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0100d51:	05 00 00 0f 00       	add    $0xf0000,%eax
f0100d56:	c1 e0 0c             	shl    $0xc,%eax
f0100d59:	39 c3                	cmp    %eax,%ebx
f0100d5b:	77 08                	ja     f0100d65 <mon_showmemory+0x4e>
f0100d5d:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0100d63:	77 15                	ja     f0100d7a <mon_showmemory+0x63>
	{
		cprintf("Invalid virturall address.\n");
f0100d65:	83 ec 0c             	sub    $0xc,%esp
f0100d68:	68 26 41 10 f0       	push   $0xf0104126
f0100d6d:	e8 84 20 00 00       	call   f0102df6 <cprintf>
		return 0;
f0100d72:	83 c4 10             	add    $0x10,%esp
f0100d75:	e9 be 00 00 00       	jmp    f0100e38 <mon_showmemory+0x121>
	}
	size_t offset = va % PGSIZE;
	pte_t* pte = pgdir_walk(kern_pgdir,(char*)va,0);
f0100d7a:	83 ec 04             	sub    $0x4,%esp
f0100d7d:	6a 00                	push   $0x0
f0100d7f:	53                   	push   %ebx
f0100d80:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0100d86:	e8 82 07 00 00       	call   f010150d <pgdir_walk>
	if (!pte || !((*pte)&PTE_P))
f0100d8b:	83 c4 10             	add    $0x10,%esp
f0100d8e:	85 c0                	test   %eax,%eax
f0100d90:	74 06                	je     f0100d98 <mon_showmemory+0x81>
f0100d92:	8b 00                	mov    (%eax),%eax
f0100d94:	a8 01                	test   $0x1,%al
f0100d96:	75 15                	jne    f0100dad <mon_showmemory+0x96>
	{
		cprintf("this address not read.\n");
f0100d98:	83 ec 0c             	sub    $0xc,%esp
f0100d9b:	68 42 41 10 f0       	push   $0xf0104142
f0100da0:	e8 51 20 00 00       	call   f0102df6 <cprintf>
		return 0;
f0100da5:	83 c4 10             	add    $0x10,%esp
f0100da8:	e9 8b 00 00 00       	jmp    f0100e38 <mon_showmemory+0x121>
	}
	unsigned char* pa = KADDR(PTE_ADDR(*pte));
f0100dad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100db2:	89 c2                	mov    %eax,%edx
f0100db4:	c1 ea 0c             	shr    $0xc,%edx
f0100db7:	39 15 68 89 11 f0    	cmp    %edx,0xf0118968
f0100dbd:	77 15                	ja     f0100dd4 <mon_showmemory+0xbd>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dbf:	50                   	push   %eax
f0100dc0:	68 c4 43 10 f0       	push   $0xf01043c4
f0100dc5:	68 ff 00 00 00       	push   $0xff
f0100dca:	68 0d 41 10 f0       	push   $0xf010410d
f0100dcf:	e8 b7 f2 ff ff       	call   f010008b <_panic>
	pa += offset;
f0100dd4:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
f0100dda:	8d 9c 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%ebx
	cprintf("%p: %x\n",pa,*pa);
f0100de1:	83 ec 04             	sub    $0x4,%esp
f0100de4:	0f b6 03             	movzbl (%ebx),%eax
f0100de7:	50                   	push   %eax
f0100de8:	53                   	push   %ebx
f0100de9:	68 5a 41 10 f0       	push   $0xf010415a
f0100dee:	e8 03 20 00 00       	call   f0102df6 <cprintf>
	cprintf("%p: %x\n",pa+1,*(pa+1));
f0100df3:	83 c4 0c             	add    $0xc,%esp
f0100df6:	0f b6 43 01          	movzbl 0x1(%ebx),%eax
f0100dfa:	50                   	push   %eax
f0100dfb:	8d 43 01             	lea    0x1(%ebx),%eax
f0100dfe:	50                   	push   %eax
f0100dff:	68 5a 41 10 f0       	push   $0xf010415a
f0100e04:	e8 ed 1f 00 00       	call   f0102df6 <cprintf>
	cprintf("%p: %x\n",pa+2,*(pa+2));
f0100e09:	83 c4 0c             	add    $0xc,%esp
f0100e0c:	0f b6 43 02          	movzbl 0x2(%ebx),%eax
f0100e10:	50                   	push   %eax
f0100e11:	8d 43 02             	lea    0x2(%ebx),%eax
f0100e14:	50                   	push   %eax
f0100e15:	68 5a 41 10 f0       	push   $0xf010415a
f0100e1a:	e8 d7 1f 00 00       	call   f0102df6 <cprintf>
	cprintf("%p: %x\n",pa+3,*(pa+3));
f0100e1f:	83 c4 0c             	add    $0xc,%esp
f0100e22:	0f b6 43 03          	movzbl 0x3(%ebx),%eax
f0100e26:	50                   	push   %eax
f0100e27:	83 c3 03             	add    $0x3,%ebx
f0100e2a:	53                   	push   %ebx
f0100e2b:	68 5a 41 10 f0       	push   $0xf010415a
f0100e30:	e8 c1 1f 00 00       	call   f0102df6 <cprintf>
	return 0;
f0100e35:	83 c4 10             	add    $0x10,%esp
}
f0100e38:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e3d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e40:	c9                   	leave  
f0100e41:	c3                   	ret    

f0100e42 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100e42:	55                   	push   %ebp
f0100e43:	89 e5                	mov    %esp,%ebp
f0100e45:	57                   	push   %edi
f0100e46:	56                   	push   %esi
f0100e47:	53                   	push   %ebx
f0100e48:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100e4b:	68 e8 43 10 f0       	push   $0xf01043e8
f0100e50:	e8 a1 1f 00 00       	call   f0102df6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100e55:	c7 04 24 0c 44 10 f0 	movl   $0xf010440c,(%esp)
f0100e5c:	e8 95 1f 00 00       	call   f0102df6 <cprintf>
f0100e61:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100e64:	83 ec 0c             	sub    $0xc,%esp
f0100e67:	68 62 41 10 f0       	push   $0xf0104162
f0100e6c:	e8 e9 27 00 00       	call   f010365a <readline>
f0100e71:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100e73:	83 c4 10             	add    $0x10,%esp
f0100e76:	85 c0                	test   %eax,%eax
f0100e78:	74 ea                	je     f0100e64 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100e7a:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100e81:	be 00 00 00 00       	mov    $0x0,%esi
f0100e86:	eb 0a                	jmp    f0100e92 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100e88:	c6 03 00             	movb   $0x0,(%ebx)
f0100e8b:	89 f7                	mov    %esi,%edi
f0100e8d:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100e90:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100e92:	0f b6 03             	movzbl (%ebx),%eax
f0100e95:	84 c0                	test   %al,%al
f0100e97:	74 63                	je     f0100efc <monitor+0xba>
f0100e99:	83 ec 08             	sub    $0x8,%esp
f0100e9c:	0f be c0             	movsbl %al,%eax
f0100e9f:	50                   	push   %eax
f0100ea0:	68 66 41 10 f0       	push   $0xf0104166
f0100ea5:	e8 ca 29 00 00       	call   f0103874 <strchr>
f0100eaa:	83 c4 10             	add    $0x10,%esp
f0100ead:	85 c0                	test   %eax,%eax
f0100eaf:	75 d7                	jne    f0100e88 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100eb1:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100eb4:	74 46                	je     f0100efc <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100eb6:	83 fe 0f             	cmp    $0xf,%esi
f0100eb9:	75 14                	jne    f0100ecf <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100ebb:	83 ec 08             	sub    $0x8,%esp
f0100ebe:	6a 10                	push   $0x10
f0100ec0:	68 6b 41 10 f0       	push   $0xf010416b
f0100ec5:	e8 2c 1f 00 00       	call   f0102df6 <cprintf>
f0100eca:	83 c4 10             	add    $0x10,%esp
f0100ecd:	eb 95                	jmp    f0100e64 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100ecf:	8d 7e 01             	lea    0x1(%esi),%edi
f0100ed2:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100ed6:	eb 03                	jmp    f0100edb <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100ed8:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100edb:	0f b6 03             	movzbl (%ebx),%eax
f0100ede:	84 c0                	test   %al,%al
f0100ee0:	74 ae                	je     f0100e90 <monitor+0x4e>
f0100ee2:	83 ec 08             	sub    $0x8,%esp
f0100ee5:	0f be c0             	movsbl %al,%eax
f0100ee8:	50                   	push   %eax
f0100ee9:	68 66 41 10 f0       	push   $0xf0104166
f0100eee:	e8 81 29 00 00       	call   f0103874 <strchr>
f0100ef3:	83 c4 10             	add    $0x10,%esp
f0100ef6:	85 c0                	test   %eax,%eax
f0100ef8:	74 de                	je     f0100ed8 <monitor+0x96>
f0100efa:	eb 94                	jmp    f0100e90 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100efc:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100f03:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100f04:	85 f6                	test   %esi,%esi
f0100f06:	0f 84 58 ff ff ff    	je     f0100e64 <monitor+0x22>
f0100f0c:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100f11:	83 ec 08             	sub    $0x8,%esp
f0100f14:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100f17:	ff 34 85 a0 45 10 f0 	pushl  -0xfefba60(,%eax,4)
f0100f1e:	ff 75 a8             	pushl  -0x58(%ebp)
f0100f21:	e8 f0 28 00 00       	call   f0103816 <strcmp>
f0100f26:	83 c4 10             	add    $0x10,%esp
f0100f29:	85 c0                	test   %eax,%eax
f0100f2b:	75 21                	jne    f0100f4e <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f0100f2d:	83 ec 04             	sub    $0x4,%esp
f0100f30:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100f33:	ff 75 08             	pushl  0x8(%ebp)
f0100f36:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100f39:	52                   	push   %edx
f0100f3a:	56                   	push   %esi
f0100f3b:	ff 14 85 a8 45 10 f0 	call   *-0xfefba58(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100f42:	83 c4 10             	add    $0x10,%esp
f0100f45:	85 c0                	test   %eax,%eax
f0100f47:	78 25                	js     f0100f6e <monitor+0x12c>
f0100f49:	e9 16 ff ff ff       	jmp    f0100e64 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100f4e:	83 c3 01             	add    $0x1,%ebx
f0100f51:	83 fb 08             	cmp    $0x8,%ebx
f0100f54:	75 bb                	jne    f0100f11 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100f56:	83 ec 08             	sub    $0x8,%esp
f0100f59:	ff 75 a8             	pushl  -0x58(%ebp)
f0100f5c:	68 88 41 10 f0       	push   $0xf0104188
f0100f61:	e8 90 1e 00 00       	call   f0102df6 <cprintf>
f0100f66:	83 c4 10             	add    $0x10,%esp
f0100f69:	e9 f6 fe ff ff       	jmp    f0100e64 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100f6e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f71:	5b                   	pop    %ebx
f0100f72:	5e                   	pop    %esi
f0100f73:	5f                   	pop    %edi
f0100f74:	5d                   	pop    %ebp
f0100f75:	c3                   	ret    

f0100f76 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100f76:	55                   	push   %ebp
f0100f77:	89 e5                	mov    %esp,%ebp
f0100f79:	56                   	push   %esi
f0100f7a:	53                   	push   %ebx
f0100f7b:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100f7d:	83 ec 0c             	sub    $0xc,%esp
f0100f80:	50                   	push   %eax
f0100f81:	e8 09 1e 00 00       	call   f0102d8f <mc146818_read>
f0100f86:	89 c6                	mov    %eax,%esi
f0100f88:	83 c3 01             	add    $0x1,%ebx
f0100f8b:	89 1c 24             	mov    %ebx,(%esp)
f0100f8e:	e8 fc 1d 00 00       	call   f0102d8f <mc146818_read>
f0100f93:	c1 e0 08             	shl    $0x8,%eax
f0100f96:	09 f0                	or     %esi,%eax
}
f0100f98:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f9b:	5b                   	pop    %ebx
f0100f9c:	5e                   	pop    %esi
f0100f9d:	5d                   	pop    %ebp
f0100f9e:	c3                   	ret    

f0100f9f <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100f9f:	83 3d 38 85 11 f0 00 	cmpl   $0x0,0xf0118538
f0100fa6:	75 11                	jne    f0100fb9 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100fa8:	ba 5f 99 11 f0       	mov    $0xf011995f,%edx
f0100fad:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100fb3:	89 15 38 85 11 f0    	mov    %edx,0xf0118538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n == 0)
f0100fb9:	85 c0                	test   %eax,%eax
f0100fbb:	75 06                	jne    f0100fc3 <boot_alloc+0x24>
		return nextfree;
f0100fbd:	a1 38 85 11 f0       	mov    0xf0118538,%eax
f0100fc2:	c3                   	ret    
	char *fuckjos = ROUNDUP(nextfree+n,PGSIZE);
f0100fc3:	8b 15 38 85 11 f0    	mov    0xf0118538,%edx
f0100fc9:	8d 8c 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%ecx
f0100fd0:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	if ((uintptr_t)fuckjos >= KERNBASE + npages*PGSIZE)
f0100fd6:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0100fdb:	05 00 00 0f 00       	add    $0xf0000,%eax
f0100fe0:	c1 e0 0c             	shl    $0xc,%eax
f0100fe3:	39 c1                	cmp    %eax,%ecx
f0100fe5:	72 17                	jb     f0100ffe <boot_alloc+0x5f>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100fe7:	55                   	push   %ebp
f0100fe8:	89 e5                	mov    %esp,%ebp
f0100fea:	83 ec 0c             	sub    $0xc,%esp
	// LAB 2: Your code here.
	if (n == 0)
		return nextfree;
	char *fuckjos = ROUNDUP(nextfree+n,PGSIZE);
	if ((uintptr_t)fuckjos >= KERNBASE + npages*PGSIZE)
		panic("boot_alloc: out of memory\n");
f0100fed:	68 00 46 10 f0       	push   $0xf0104600
f0100ff2:	6a 6d                	push   $0x6d
f0100ff4:	68 1b 46 10 f0       	push   $0xf010461b
f0100ff9:	e8 8d f0 ff ff       	call   f010008b <_panic>
	else 
	{
		char *whattoreturn = nextfree; 
		nextfree = fuckjos;
f0100ffe:	89 0d 38 85 11 f0    	mov    %ecx,0xf0118538
		return whattoreturn;
f0101004:	89 d0                	mov    %edx,%eax
	}
	return NULL;
}
f0101006:	c3                   	ret    

f0101007 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0101007:	89 d1                	mov    %edx,%ecx
f0101009:	c1 e9 16             	shr    $0x16,%ecx
f010100c:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010100f:	a8 01                	test   $0x1,%al
f0101011:	74 52                	je     f0101065 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0101013:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101018:	89 c1                	mov    %eax,%ecx
f010101a:	c1 e9 0c             	shr    $0xc,%ecx
f010101d:	3b 0d 68 89 11 f0    	cmp    0xf0118968,%ecx
f0101023:	72 1b                	jb     f0101040 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0101025:	55                   	push   %ebp
f0101026:	89 e5                	mov    %esp,%ebp
f0101028:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010102b:	50                   	push   %eax
f010102c:	68 c4 43 10 f0       	push   $0xf01043c4
f0101031:	68 e3 02 00 00       	push   $0x2e3
f0101036:	68 1b 46 10 f0       	push   $0xf010461b
f010103b:	e8 4b f0 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0101040:	c1 ea 0c             	shr    $0xc,%edx
f0101043:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101049:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0101050:	89 c2                	mov    %eax,%edx
f0101052:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0101055:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010105a:	85 d2                	test   %edx,%edx
f010105c:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0101061:	0f 44 c2             	cmove  %edx,%eax
f0101064:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0101065:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f010106a:	c3                   	ret    

f010106b <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f010106b:	55                   	push   %ebp
f010106c:	89 e5                	mov    %esp,%ebp
f010106e:	57                   	push   %edi
f010106f:	56                   	push   %esi
f0101070:	53                   	push   %ebx
f0101071:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101074:	84 c0                	test   %al,%al
f0101076:	0f 85 81 02 00 00    	jne    f01012fd <check_page_free_list+0x292>
f010107c:	e9 8e 02 00 00       	jmp    f010130f <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0101081:	83 ec 04             	sub    $0x4,%esp
f0101084:	68 0c 49 10 f0       	push   $0xf010490c
f0101089:	68 24 02 00 00       	push   $0x224
f010108e:	68 1b 46 10 f0       	push   $0xf010461b
f0101093:	e8 f3 ef ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0101098:	8d 55 d8             	lea    -0x28(%ebp),%edx
f010109b:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010109e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01010a1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01010a4:	89 c2                	mov    %eax,%edx
f01010a6:	2b 15 70 89 11 f0    	sub    0xf0118970,%edx
f01010ac:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01010b2:	0f 95 c2             	setne  %dl
f01010b5:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01010b8:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01010bc:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01010be:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01010c2:	8b 00                	mov    (%eax),%eax
f01010c4:	85 c0                	test   %eax,%eax
f01010c6:	75 dc                	jne    f01010a4 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01010c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010cb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01010d1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010d4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010d7:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01010d9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010dc:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01010e1:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01010e6:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
f01010ec:	eb 53                	jmp    f0101141 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010ee:	89 d8                	mov    %ebx,%eax
f01010f0:	2b 05 70 89 11 f0    	sub    0xf0118970,%eax
f01010f6:	c1 f8 03             	sar    $0x3,%eax
f01010f9:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f01010fc:	89 c2                	mov    %eax,%edx
f01010fe:	c1 ea 16             	shr    $0x16,%edx
f0101101:	39 f2                	cmp    %esi,%edx
f0101103:	73 3a                	jae    f010113f <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101105:	89 c2                	mov    %eax,%edx
f0101107:	c1 ea 0c             	shr    $0xc,%edx
f010110a:	3b 15 68 89 11 f0    	cmp    0xf0118968,%edx
f0101110:	72 12                	jb     f0101124 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101112:	50                   	push   %eax
f0101113:	68 c4 43 10 f0       	push   $0xf01043c4
f0101118:	6a 52                	push   $0x52
f010111a:	68 27 46 10 f0       	push   $0xf0104627
f010111f:	e8 67 ef ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0101124:	83 ec 04             	sub    $0x4,%esp
f0101127:	68 80 00 00 00       	push   $0x80
f010112c:	68 97 00 00 00       	push   $0x97
f0101131:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101136:	50                   	push   %eax
f0101137:	e8 75 27 00 00       	call   f01038b1 <memset>
f010113c:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010113f:	8b 1b                	mov    (%ebx),%ebx
f0101141:	85 db                	test   %ebx,%ebx
f0101143:	75 a9                	jne    f01010ee <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0101145:	b8 00 00 00 00       	mov    $0x0,%eax
f010114a:	e8 50 fe ff ff       	call   f0100f9f <boot_alloc>
f010114f:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101152:	8b 15 3c 85 11 f0    	mov    0xf011853c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101158:	8b 0d 70 89 11 f0    	mov    0xf0118970,%ecx
		assert(pp < pages + npages);
f010115e:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101163:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101166:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101169:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f010116c:	be 00 00 00 00       	mov    $0x0,%esi
f0101171:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101174:	e9 30 01 00 00       	jmp    f01012a9 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101179:	39 ca                	cmp    %ecx,%edx
f010117b:	73 19                	jae    f0101196 <check_page_free_list+0x12b>
f010117d:	68 35 46 10 f0       	push   $0xf0104635
f0101182:	68 41 46 10 f0       	push   $0xf0104641
f0101187:	68 3e 02 00 00       	push   $0x23e
f010118c:	68 1b 46 10 f0       	push   $0xf010461b
f0101191:	e8 f5 ee ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0101196:	39 fa                	cmp    %edi,%edx
f0101198:	72 19                	jb     f01011b3 <check_page_free_list+0x148>
f010119a:	68 56 46 10 f0       	push   $0xf0104656
f010119f:	68 41 46 10 f0       	push   $0xf0104641
f01011a4:	68 3f 02 00 00       	push   $0x23f
f01011a9:	68 1b 46 10 f0       	push   $0xf010461b
f01011ae:	e8 d8 ee ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01011b3:	89 d0                	mov    %edx,%eax
f01011b5:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f01011b8:	a8 07                	test   $0x7,%al
f01011ba:	74 19                	je     f01011d5 <check_page_free_list+0x16a>
f01011bc:	68 30 49 10 f0       	push   $0xf0104930
f01011c1:	68 41 46 10 f0       	push   $0xf0104641
f01011c6:	68 40 02 00 00       	push   $0x240
f01011cb:	68 1b 46 10 f0       	push   $0xf010461b
f01011d0:	e8 b6 ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011d5:	c1 f8 03             	sar    $0x3,%eax
f01011d8:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f01011db:	85 c0                	test   %eax,%eax
f01011dd:	75 19                	jne    f01011f8 <check_page_free_list+0x18d>
f01011df:	68 6a 46 10 f0       	push   $0xf010466a
f01011e4:	68 41 46 10 f0       	push   $0xf0104641
f01011e9:	68 43 02 00 00       	push   $0x243
f01011ee:	68 1b 46 10 f0       	push   $0xf010461b
f01011f3:	e8 93 ee ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f01011f8:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01011fd:	75 19                	jne    f0101218 <check_page_free_list+0x1ad>
f01011ff:	68 7b 46 10 f0       	push   $0xf010467b
f0101204:	68 41 46 10 f0       	push   $0xf0104641
f0101209:	68 44 02 00 00       	push   $0x244
f010120e:	68 1b 46 10 f0       	push   $0xf010461b
f0101213:	e8 73 ee ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0101218:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f010121d:	75 19                	jne    f0101238 <check_page_free_list+0x1cd>
f010121f:	68 64 49 10 f0       	push   $0xf0104964
f0101224:	68 41 46 10 f0       	push   $0xf0104641
f0101229:	68 45 02 00 00       	push   $0x245
f010122e:	68 1b 46 10 f0       	push   $0xf010461b
f0101233:	e8 53 ee ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101238:	3d 00 00 10 00       	cmp    $0x100000,%eax
f010123d:	75 19                	jne    f0101258 <check_page_free_list+0x1ed>
f010123f:	68 94 46 10 f0       	push   $0xf0104694
f0101244:	68 41 46 10 f0       	push   $0xf0104641
f0101249:	68 46 02 00 00       	push   $0x246
f010124e:	68 1b 46 10 f0       	push   $0xf010461b
f0101253:	e8 33 ee ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101258:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f010125d:	76 3f                	jbe    f010129e <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010125f:	89 c3                	mov    %eax,%ebx
f0101261:	c1 eb 0c             	shr    $0xc,%ebx
f0101264:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0101267:	77 12                	ja     f010127b <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101269:	50                   	push   %eax
f010126a:	68 c4 43 10 f0       	push   $0xf01043c4
f010126f:	6a 52                	push   $0x52
f0101271:	68 27 46 10 f0       	push   $0xf0104627
f0101276:	e8 10 ee ff ff       	call   f010008b <_panic>
f010127b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101280:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101283:	76 1e                	jbe    f01012a3 <check_page_free_list+0x238>
f0101285:	68 88 49 10 f0       	push   $0xf0104988
f010128a:	68 41 46 10 f0       	push   $0xf0104641
f010128f:	68 47 02 00 00       	push   $0x247
f0101294:	68 1b 46 10 f0       	push   $0xf010461b
f0101299:	e8 ed ed ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f010129e:	83 c6 01             	add    $0x1,%esi
f01012a1:	eb 04                	jmp    f01012a7 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f01012a3:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01012a7:	8b 12                	mov    (%edx),%edx
f01012a9:	85 d2                	test   %edx,%edx
f01012ab:	0f 85 c8 fe ff ff    	jne    f0101179 <check_page_free_list+0x10e>
f01012b1:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f01012b4:	85 f6                	test   %esi,%esi
f01012b6:	7f 19                	jg     f01012d1 <check_page_free_list+0x266>
f01012b8:	68 ae 46 10 f0       	push   $0xf01046ae
f01012bd:	68 41 46 10 f0       	push   $0xf0104641
f01012c2:	68 4f 02 00 00       	push   $0x24f
f01012c7:	68 1b 46 10 f0       	push   $0xf010461b
f01012cc:	e8 ba ed ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f01012d1:	85 db                	test   %ebx,%ebx
f01012d3:	7f 19                	jg     f01012ee <check_page_free_list+0x283>
f01012d5:	68 c0 46 10 f0       	push   $0xf01046c0
f01012da:	68 41 46 10 f0       	push   $0xf0104641
f01012df:	68 50 02 00 00       	push   $0x250
f01012e4:	68 1b 46 10 f0       	push   $0xf010461b
f01012e9:	e8 9d ed ff ff       	call   f010008b <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f01012ee:	83 ec 0c             	sub    $0xc,%esp
f01012f1:	68 d0 49 10 f0       	push   $0xf01049d0
f01012f6:	e8 fb 1a 00 00       	call   f0102df6 <cprintf>
}
f01012fb:	eb 29                	jmp    f0101326 <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f01012fd:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0101302:	85 c0                	test   %eax,%eax
f0101304:	0f 85 8e fd ff ff    	jne    f0101098 <check_page_free_list+0x2d>
f010130a:	e9 72 fd ff ff       	jmp    f0101081 <check_page_free_list+0x16>
f010130f:	83 3d 3c 85 11 f0 00 	cmpl   $0x0,0xf011853c
f0101316:	0f 84 65 fd ff ff    	je     f0101081 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010131c:	be 00 04 00 00       	mov    $0x400,%esi
f0101321:	e9 c0 fd ff ff       	jmp    f01010e6 <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0101326:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101329:	5b                   	pop    %ebx
f010132a:	5e                   	pop    %esi
f010132b:	5f                   	pop    %edi
f010132c:	5d                   	pop    %ebp
f010132d:	c3                   	ret    

f010132e <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f010132e:	55                   	push   %ebp
f010132f:	89 e5                	mov    %esp,%ebp
f0101331:	56                   	push   %esi
f0101332:	53                   	push   %ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	//1)
	pages[0].pp_ref = 1;
f0101333:	a1 70 89 11 f0       	mov    0xf0118970,%eax
f0101338:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f010133e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	//2)
	for (i=1;i<npages_basemem;i++)
f0101344:	8b 1d 40 85 11 f0    	mov    0xf0118540,%ebx
f010134a:	8b 35 3c 85 11 f0    	mov    0xf011853c,%esi
f0101350:	ba 00 00 00 00       	mov    $0x0,%edx
f0101355:	b8 01 00 00 00       	mov    $0x1,%eax
f010135a:	eb 27                	jmp    f0101383 <page_init+0x55>
	{
		pages[i].pp_ref = 0;
f010135c:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0101363:	89 d1                	mov    %edx,%ecx
f0101365:	03 0d 70 89 11 f0    	add    0xf0118970,%ecx
f010136b:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0101371:	89 31                	mov    %esi,(%ecx)
	size_t i;
	//1)
	pages[0].pp_ref = 1;
	pages[0].pp_link = NULL;
	//2)
	for (i=1;i<npages_basemem;i++)
f0101373:	83 c0 01             	add    $0x1,%eax
	{
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0101376:	89 d6                	mov    %edx,%esi
f0101378:	03 35 70 89 11 f0    	add    0xf0118970,%esi
f010137e:	ba 01 00 00 00       	mov    $0x1,%edx
	size_t i;
	//1)
	pages[0].pp_ref = 1;
	pages[0].pp_link = NULL;
	//2)
	for (i=1;i<npages_basemem;i++)
f0101383:	39 d8                	cmp    %ebx,%eax
f0101385:	72 d5                	jb     f010135c <page_init+0x2e>
f0101387:	84 d2                	test   %dl,%dl
f0101389:	74 06                	je     f0101391 <page_init+0x63>
f010138b:	89 35 3c 85 11 f0    	mov    %esi,0xf011853c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	//3)
	size_t fstpgid = PGNUM(PADDR(boot_alloc(0)));
f0101391:	b8 00 00 00 00       	mov    $0x0,%eax
f0101396:	e8 04 fc ff ff       	call   f0100f9f <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010139b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013a0:	77 15                	ja     f01013b7 <page_init+0x89>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013a2:	50                   	push   %eax
f01013a3:	68 f4 49 10 f0       	push   $0xf01049f4
f01013a8:	68 15 01 00 00       	push   $0x115
f01013ad:	68 1b 46 10 f0       	push   $0xf010461b
f01013b2:	e8 d4 ec ff ff       	call   f010008b <_panic>
f01013b7:	05 00 00 00 10       	add    $0x10000000,%eax
f01013bc:	c1 e8 0c             	shr    $0xc,%eax
f01013bf:	8d 14 dd 00 00 00 00 	lea    0x0(,%ebx,8),%edx
	for (i=npages_basemem;i<fstpgid;i++)
f01013c6:	eb 1a                	jmp    f01013e2 <page_init+0xb4>
	{
		pages[i].pp_ref = 1;
f01013c8:	89 d1                	mov    %edx,%ecx
f01013ca:	03 0d 70 89 11 f0    	add    0xf0118970,%ecx
f01013d0:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
		pages[i].pp_link = NULL;
f01013d6:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	//3)
	size_t fstpgid = PGNUM(PADDR(boot_alloc(0)));
	for (i=npages_basemem;i<fstpgid;i++)
f01013dc:	83 c3 01             	add    $0x1,%ebx
f01013df:	83 c2 08             	add    $0x8,%edx
f01013e2:	39 c3                	cmp    %eax,%ebx
f01013e4:	72 e2                	jb     f01013c8 <page_init+0x9a>
f01013e6:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
f01013ec:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f01013f3:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013f8:	eb 23                	jmp    f010141d <page_init+0xef>
		pages[i].pp_link = NULL;
	}
	//4)
	for (i=fstpgid;i<npages;i++)
	{
		pages[i].pp_ref = 0;
f01013fa:	89 d1                	mov    %edx,%ecx
f01013fc:	03 0d 70 89 11 f0    	add    0xf0118970,%ecx
f0101402:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0101408:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f010140a:	89 d3                	mov    %edx,%ebx
f010140c:	03 1d 70 89 11 f0    	add    0xf0118970,%ebx
	{
		pages[i].pp_ref = 1;
		pages[i].pp_link = NULL;
	}
	//4)
	for (i=fstpgid;i<npages;i++)
f0101412:	83 c0 01             	add    $0x1,%eax
f0101415:	83 c2 08             	add    $0x8,%edx
f0101418:	b9 01 00 00 00       	mov    $0x1,%ecx
f010141d:	3b 05 68 89 11 f0    	cmp    0xf0118968,%eax
f0101423:	72 d5                	jb     f01013fa <page_init+0xcc>
f0101425:	84 c9                	test   %cl,%cl
f0101427:	74 06                	je     f010142f <page_init+0x101>
f0101429:	89 1d 3c 85 11 f0    	mov    %ebx,0xf011853c
		
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}*/
}
f010142f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101432:	5b                   	pop    %ebx
f0101433:	5e                   	pop    %esi
f0101434:	5d                   	pop    %ebp
f0101435:	c3                   	ret    

f0101436 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0101436:	55                   	push   %ebp
f0101437:	89 e5                	mov    %esp,%ebp
f0101439:	53                   	push   %ebx
f010143a:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if (page_free_list == NULL) return NULL;
f010143d:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
f0101443:	85 db                	test   %ebx,%ebx
f0101445:	74 5d                	je     f01014a4 <page_alloc+0x6e>
	struct PageInfo* fuckingjos = page_free_list;
	if (alloc_flags && ALLOC_ZERO)
f0101447:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010144b:	74 45                	je     f0101492 <page_alloc+0x5c>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010144d:	89 d8                	mov    %ebx,%eax
f010144f:	2b 05 70 89 11 f0    	sub    0xf0118970,%eax
f0101455:	c1 f8 03             	sar    $0x3,%eax
f0101458:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010145b:	89 c2                	mov    %eax,%edx
f010145d:	c1 ea 0c             	shr    $0xc,%edx
f0101460:	3b 15 68 89 11 f0    	cmp    0xf0118968,%edx
f0101466:	72 12                	jb     f010147a <page_alloc+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101468:	50                   	push   %eax
f0101469:	68 c4 43 10 f0       	push   $0xf01043c4
f010146e:	6a 52                	push   $0x52
f0101470:	68 27 46 10 f0       	push   $0xf0104627
f0101475:	e8 11 ec ff ff       	call   f010008b <_panic>
		memset(page2kva(fuckingjos),0,PGSIZE);
f010147a:	83 ec 04             	sub    $0x4,%esp
f010147d:	68 00 10 00 00       	push   $0x1000
f0101482:	6a 00                	push   $0x0
f0101484:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101489:	50                   	push   %eax
f010148a:	e8 22 24 00 00       	call   f01038b1 <memset>
f010148f:	83 c4 10             	add    $0x10,%esp
	page_free_list = page_free_list->pp_link;
f0101492:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0101497:	8b 00                	mov    (%eax),%eax
f0101499:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
	fuckingjos->pp_link = NULL;
f010149e:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	return fuckingjos;
}
f01014a4:	89 d8                	mov    %ebx,%eax
f01014a6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01014a9:	c9                   	leave  
f01014aa:	c3                   	ret    

f01014ab <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f01014ab:	55                   	push   %ebp
f01014ac:	89 e5                	mov    %esp,%ebp
f01014ae:	83 ec 08             	sub    $0x8,%esp
f01014b1:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref!=0 || pp->pp_link!=NULL)
f01014b4:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01014b9:	75 05                	jne    f01014c0 <page_free+0x15>
f01014bb:	83 38 00             	cmpl   $0x0,(%eax)
f01014be:	74 17                	je     f01014d7 <page_free+0x2c>
		panic("page_free error: this page can't be freed.\n");
f01014c0:	83 ec 04             	sub    $0x4,%esp
f01014c3:	68 18 4a 10 f0       	push   $0xf0104a18
f01014c8:	68 4a 01 00 00       	push   $0x14a
f01014cd:	68 1b 46 10 f0       	push   $0xf010461b
f01014d2:	e8 b4 eb ff ff       	call   f010008b <_panic>
	pp->pp_link = page_free_list;
f01014d7:	8b 15 3c 85 11 f0    	mov    0xf011853c,%edx
f01014dd:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f01014df:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f01014e4:	c9                   	leave  
f01014e5:	c3                   	ret    

f01014e6 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01014e6:	55                   	push   %ebp
f01014e7:	89 e5                	mov    %esp,%ebp
f01014e9:	83 ec 08             	sub    $0x8,%esp
f01014ec:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01014ef:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01014f3:	83 e8 01             	sub    $0x1,%eax
f01014f6:	66 89 42 04          	mov    %ax,0x4(%edx)
f01014fa:	66 85 c0             	test   %ax,%ax
f01014fd:	75 0c                	jne    f010150b <page_decref+0x25>
		page_free(pp);
f01014ff:	83 ec 0c             	sub    $0xc,%esp
f0101502:	52                   	push   %edx
f0101503:	e8 a3 ff ff ff       	call   f01014ab <page_free>
f0101508:	83 c4 10             	add    $0x10,%esp
}
f010150b:	c9                   	leave  
f010150c:	c3                   	ret    

f010150d <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f010150d:	55                   	push   %ebp
f010150e:	89 e5                	mov    %esp,%ebp
f0101510:	56                   	push   %esi
f0101511:	53                   	push   %ebx
f0101512:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pde_t pde = pgdir[PDX(va)];
f0101515:	89 de                	mov    %ebx,%esi
f0101517:	c1 ee 16             	shr    $0x16,%esi
f010151a:	c1 e6 02             	shl    $0x2,%esi
f010151d:	03 75 08             	add    0x8(%ebp),%esi
f0101520:	8b 06                	mov    (%esi),%eax
	if (!(pde & PTE_P))
f0101522:	a8 01                	test   $0x1,%al
f0101524:	75 2d                	jne    f0101553 <pgdir_walk+0x46>
	{
		if (!create) return NULL;
f0101526:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010152a:	74 60                	je     f010158c <pgdir_walk+0x7f>
		struct PageInfo* pp = page_alloc(ALLOC_ZERO);
f010152c:	83 ec 0c             	sub    $0xc,%esp
f010152f:	6a 01                	push   $0x1
f0101531:	e8 00 ff ff ff       	call   f0101436 <page_alloc>
		if (pp == NULL) return NULL;
f0101536:	83 c4 10             	add    $0x10,%esp
f0101539:	85 c0                	test   %eax,%eax
f010153b:	74 56                	je     f0101593 <pgdir_walk+0x86>
		pp->pp_ref++;
f010153d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		pde = page2pa(pp) | PTE_W | PTE_P | PTE_U;
f0101542:	2b 05 70 89 11 f0    	sub    0xf0118970,%eax
f0101548:	c1 f8 03             	sar    $0x3,%eax
f010154b:	c1 e0 0c             	shl    $0xc,%eax
f010154e:	83 c8 07             	or     $0x7,%eax
		pgdir[PDX(va)] = pde;
f0101551:	89 06                	mov    %eax,(%esi)
	}
	pte_t* pgtbl = (pte_t*)KADDR(PTE_ADDR(pde));
f0101553:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101558:	89 c2                	mov    %eax,%edx
f010155a:	c1 ea 0c             	shr    $0xc,%edx
f010155d:	3b 15 68 89 11 f0    	cmp    0xf0118968,%edx
f0101563:	72 15                	jb     f010157a <pgdir_walk+0x6d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101565:	50                   	push   %eax
f0101566:	68 c4 43 10 f0       	push   $0xf01043c4
f010156b:	68 81 01 00 00       	push   $0x181
f0101570:	68 1b 46 10 f0       	push   $0xf010461b
f0101575:	e8 11 eb ff ff       	call   f010008b <_panic>
	return &pgtbl[PTX(va)];
f010157a:	c1 eb 0a             	shr    $0xa,%ebx
f010157d:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101583:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f010158a:	eb 0c                	jmp    f0101598 <pgdir_walk+0x8b>
{
	// Fill this function in
	pde_t pde = pgdir[PDX(va)];
	if (!(pde & PTE_P))
	{
		if (!create) return NULL;
f010158c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101591:	eb 05                	jmp    f0101598 <pgdir_walk+0x8b>
		struct PageInfo* pp = page_alloc(ALLOC_ZERO);
		if (pp == NULL) return NULL;
f0101593:	b8 00 00 00 00       	mov    $0x0,%eax
		pde = page2pa(pp) | PTE_W | PTE_P | PTE_U;
		pgdir[PDX(va)] = pde;
	}
	pte_t* pgtbl = (pte_t*)KADDR(PTE_ADDR(pde));
	return &pgtbl[PTX(va)];
}
f0101598:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010159b:	5b                   	pop    %ebx
f010159c:	5e                   	pop    %esi
f010159d:	5d                   	pop    %ebp
f010159e:	c3                   	ret    

f010159f <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010159f:	55                   	push   %ebp
f01015a0:	89 e5                	mov    %esp,%ebp
f01015a2:	57                   	push   %edi
f01015a3:	56                   	push   %esi
f01015a4:	53                   	push   %ebx
f01015a5:	83 ec 1c             	sub    $0x1c,%esp
f01015a8:	89 c7                	mov    %eax,%edi
f01015aa:	89 d6                	mov    %edx,%esi
f01015ac:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	size_t i;
	for (i=0;i<size;i+=PGSIZE)
f01015af:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		pte_t* now = pgdir_walk(pgdir,(char*)(va+i),1);
		assert(now != NULL);
		*now = (pa+i) | perm | PTE_P;
f01015b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015b7:	83 c8 01             	or     $0x1,%eax
f01015ba:	89 45 e0             	mov    %eax,-0x20(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	size_t i;
	for (i=0;i<size;i+=PGSIZE)
f01015bd:	eb 3f                	jmp    f01015fe <boot_map_region+0x5f>
	{
		pte_t* now = pgdir_walk(pgdir,(char*)(va+i),1);
f01015bf:	83 ec 04             	sub    $0x4,%esp
f01015c2:	6a 01                	push   $0x1
f01015c4:	8d 04 33             	lea    (%ebx,%esi,1),%eax
f01015c7:	50                   	push   %eax
f01015c8:	57                   	push   %edi
f01015c9:	e8 3f ff ff ff       	call   f010150d <pgdir_walk>
		assert(now != NULL);
f01015ce:	83 c4 10             	add    $0x10,%esp
f01015d1:	85 c0                	test   %eax,%eax
f01015d3:	75 19                	jne    f01015ee <boot_map_region+0x4f>
f01015d5:	68 d1 46 10 f0       	push   $0xf01046d1
f01015da:	68 41 46 10 f0       	push   $0xf0104641
f01015df:	68 97 01 00 00       	push   $0x197
f01015e4:	68 1b 46 10 f0       	push   $0xf010461b
f01015e9:	e8 9d ea ff ff       	call   f010008b <_panic>
		*now = (pa+i) | perm | PTE_P;
f01015ee:	89 da                	mov    %ebx,%edx
f01015f0:	03 55 08             	add    0x8(%ebp),%edx
f01015f3:	0b 55 e0             	or     -0x20(%ebp),%edx
f01015f6:	89 10                	mov    %edx,(%eax)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	size_t i;
	for (i=0;i<size;i+=PGSIZE)
f01015f8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01015fe:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101601:	72 bc                	jb     f01015bf <boot_map_region+0x20>
		pte_t* now = pgdir_walk(pgdir,(char*)(va+i),1);
		assert(now != NULL);
		*now = (pa+i) | perm | PTE_P;
	}
	// Fill this function in
}
f0101603:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101606:	5b                   	pop    %ebx
f0101607:	5e                   	pop    %esi
f0101608:	5f                   	pop    %edi
f0101609:	5d                   	pop    %ebp
f010160a:	c3                   	ret    

f010160b <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010160b:	55                   	push   %ebp
f010160c:	89 e5                	mov    %esp,%ebp
f010160e:	53                   	push   %ebx
f010160f:	83 ec 08             	sub    $0x8,%esp
f0101612:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t* pte = pgdir_walk(pgdir,va,0);
f0101615:	6a 00                	push   $0x0
f0101617:	ff 75 0c             	pushl  0xc(%ebp)
f010161a:	ff 75 08             	pushl  0x8(%ebp)
f010161d:	e8 eb fe ff ff       	call   f010150d <pgdir_walk>
	if (!pte || !((*pte) & PTE_P)) return NULL;
f0101622:	83 c4 10             	add    $0x10,%esp
f0101625:	85 c0                	test   %eax,%eax
f0101627:	74 37                	je     f0101660 <page_lookup+0x55>
f0101629:	f6 00 01             	testb  $0x1,(%eax)
f010162c:	74 39                	je     f0101667 <page_lookup+0x5c>
	if (pte_store) 
f010162e:	85 db                	test   %ebx,%ebx
f0101630:	74 02                	je     f0101634 <page_lookup+0x29>
		*pte_store = pte;
f0101632:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101634:	8b 00                	mov    (%eax),%eax
f0101636:	c1 e8 0c             	shr    $0xc,%eax
f0101639:	3b 05 68 89 11 f0    	cmp    0xf0118968,%eax
f010163f:	72 14                	jb     f0101655 <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0101641:	83 ec 04             	sub    $0x4,%esp
f0101644:	68 44 4a 10 f0       	push   $0xf0104a44
f0101649:	6a 4b                	push   $0x4b
f010164b:	68 27 46 10 f0       	push   $0xf0104627
f0101650:	e8 36 ea ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0101655:	8b 15 70 89 11 f0    	mov    0xf0118970,%edx
f010165b:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));
f010165e:	eb 0c                	jmp    f010166c <page_lookup+0x61>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t* pte = pgdir_walk(pgdir,va,0);
	if (!pte || !((*pte) & PTE_P)) return NULL;
f0101660:	b8 00 00 00 00       	mov    $0x0,%eax
f0101665:	eb 05                	jmp    f010166c <page_lookup+0x61>
f0101667:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store) 
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f010166c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010166f:	c9                   	leave  
f0101670:	c3                   	ret    

f0101671 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{	
f0101671:	55                   	push   %ebp
f0101672:	89 e5                	mov    %esp,%ebp
f0101674:	56                   	push   %esi
f0101675:	53                   	push   %ebx
f0101676:	8b 75 08             	mov    0x8(%ebp),%esi
f0101679:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo* pg = page_lookup(pgdir,va,NULL);
f010167c:	83 ec 04             	sub    $0x4,%esp
f010167f:	6a 00                	push   $0x0
f0101681:	53                   	push   %ebx
f0101682:	56                   	push   %esi
f0101683:	e8 83 ff ff ff       	call   f010160b <page_lookup>
	if (pg == NULL) return;
f0101688:	83 c4 10             	add    $0x10,%esp
f010168b:	85 c0                	test   %eax,%eax
f010168d:	74 21                	je     f01016b0 <page_remove+0x3f>
	page_decref(pg);
f010168f:	83 ec 0c             	sub    $0xc,%esp
f0101692:	50                   	push   %eax
f0101693:	e8 4e fe ff ff       	call   f01014e6 <page_decref>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101698:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir,va);
	pte_t* pte = pgdir_walk(pgdir, va, 0);
f010169b:	83 c4 0c             	add    $0xc,%esp
f010169e:	6a 00                	push   $0x0
f01016a0:	53                   	push   %ebx
f01016a1:	56                   	push   %esi
f01016a2:	e8 66 fe ff ff       	call   f010150d <pgdir_walk>
	*pte = 0;
f01016a7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f01016ad:	83 c4 10             	add    $0x10,%esp
	// Fill this function in
}
f01016b0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01016b3:	5b                   	pop    %ebx
f01016b4:	5e                   	pop    %esi
f01016b5:	5d                   	pop    %ebp
f01016b6:	c3                   	ret    

f01016b7 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01016b7:	55                   	push   %ebp
f01016b8:	89 e5                	mov    %esp,%ebp
f01016ba:	57                   	push   %edi
f01016bb:	56                   	push   %esi
f01016bc:	53                   	push   %ebx
f01016bd:	83 ec 10             	sub    $0x10,%esp
f01016c0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01016c3:	8b 75 10             	mov    0x10(%ebp),%esi
	// Fill this function in
	pte_t* pte = pgdir_walk(pgdir,va,1);
f01016c6:	6a 01                	push   $0x1
f01016c8:	56                   	push   %esi
f01016c9:	ff 75 08             	pushl  0x8(%ebp)
f01016cc:	e8 3c fe ff ff       	call   f010150d <pgdir_walk>
	if (!pte) return -E_NO_MEM;
f01016d1:	83 c4 10             	add    $0x10,%esp
f01016d4:	85 c0                	test   %eax,%eax
f01016d6:	74 6c                	je     f0101744 <page_insert+0x8d>
f01016d8:	89 c7                	mov    %eax,%edi
	if ((*pte) & PTE_P) 
f01016da:	f6 00 01             	testb  $0x1,(%eax)
f01016dd:	74 12                	je     f01016f1 <page_insert+0x3a>
	{
		page_remove(pgdir,va);
f01016df:	83 ec 08             	sub    $0x8,%esp
f01016e2:	56                   	push   %esi
f01016e3:	ff 75 08             	pushl  0x8(%ebp)
f01016e6:	e8 86 ff ff ff       	call   f0101671 <page_remove>
f01016eb:	0f 01 3e             	invlpg (%esi)
f01016ee:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}
	if (pp == page_free_list)
f01016f1:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f01016f6:	39 d8                	cmp    %ebx,%eax
f01016f8:	75 12                	jne    f010170c <page_insert+0x55>
	{
		page_free_list = pp->pp_link;
f01016fa:	8b 10                	mov    (%eax),%edx
f01016fc:	89 15 3c 85 11 f0    	mov    %edx,0xf011853c
		pp->pp_link = NULL;
f0101702:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101708:	eb 16                	jmp    f0101720 <page_insert+0x69>
	}
	else
	{
		struct PageInfo* ppp = page_free_list;
		while (ppp && ppp->pp_link != pp)
			ppp = ppp->pp_link; //why don't use double linked list:(
f010170a:	89 d0                	mov    %edx,%eax
		pp->pp_link = NULL;
	}
	else
	{
		struct PageInfo* ppp = page_free_list;
		while (ppp && ppp->pp_link != pp)
f010170c:	85 c0                	test   %eax,%eax
f010170e:	74 10                	je     f0101720 <page_insert+0x69>
f0101710:	8b 10                	mov    (%eax),%edx
f0101712:	39 d3                	cmp    %edx,%ebx
f0101714:	75 f4                	jne    f010170a <page_insert+0x53>
			ppp = ppp->pp_link; //why don't use double linked list:(
		if (ppp)
		{
			ppp->pp_link=pp->pp_link;
f0101716:	8b 13                	mov    (%ebx),%edx
f0101718:	89 10                	mov    %edx,(%eax)
			pp->pp_link=NULL;
f010171a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		}
	}
	*pte = page2pa(pp) | perm | PTE_P;	
f0101720:	89 d8                	mov    %ebx,%eax
f0101722:	2b 05 70 89 11 f0    	sub    0xf0118970,%eax
f0101728:	c1 f8 03             	sar    $0x3,%eax
f010172b:	c1 e0 0c             	shl    $0xc,%eax
f010172e:	8b 55 14             	mov    0x14(%ebp),%edx
f0101731:	83 ca 01             	or     $0x1,%edx
f0101734:	09 d0                	or     %edx,%eax
f0101736:	89 07                	mov    %eax,(%edi)
	pp->pp_ref++;
f0101738:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0;
f010173d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101742:	eb 05                	jmp    f0101749 <page_insert+0x92>
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t* pte = pgdir_walk(pgdir,va,1);
	if (!pte) return -E_NO_MEM;
f0101744:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		}
	}
	*pte = page2pa(pp) | perm | PTE_P;	
	pp->pp_ref++;
	return 0;
}
f0101749:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010174c:	5b                   	pop    %ebx
f010174d:	5e                   	pop    %esi
f010174e:	5f                   	pop    %edi
f010174f:	5d                   	pop    %ebp
f0101750:	c3                   	ret    

f0101751 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101751:	55                   	push   %ebp
f0101752:	89 e5                	mov    %esp,%ebp
f0101754:	57                   	push   %edi
f0101755:	56                   	push   %esi
f0101756:	53                   	push   %ebx
f0101757:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f010175a:	b8 15 00 00 00       	mov    $0x15,%eax
f010175f:	e8 12 f8 ff ff       	call   f0100f76 <nvram_read>
f0101764:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101766:	b8 17 00 00 00       	mov    $0x17,%eax
f010176b:	e8 06 f8 ff ff       	call   f0100f76 <nvram_read>
f0101770:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101772:	b8 34 00 00 00       	mov    $0x34,%eax
f0101777:	e8 fa f7 ff ff       	call   f0100f76 <nvram_read>
f010177c:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f010177f:	85 c0                	test   %eax,%eax
f0101781:	74 07                	je     f010178a <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0101783:	05 00 40 00 00       	add    $0x4000,%eax
f0101788:	eb 0b                	jmp    f0101795 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f010178a:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101790:	85 f6                	test   %esi,%esi
f0101792:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101795:	89 c2                	mov    %eax,%edx
f0101797:	c1 ea 02             	shr    $0x2,%edx
f010179a:	89 15 68 89 11 f0    	mov    %edx,0xf0118968
	npages_basemem = basemem / (PGSIZE / 1024);
f01017a0:	89 da                	mov    %ebx,%edx
f01017a2:	c1 ea 02             	shr    $0x2,%edx
f01017a5:	89 15 40 85 11 f0    	mov    %edx,0xf0118540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01017ab:	89 c2                	mov    %eax,%edx
f01017ad:	29 da                	sub    %ebx,%edx
f01017af:	52                   	push   %edx
f01017b0:	53                   	push   %ebx
f01017b1:	50                   	push   %eax
f01017b2:	68 64 4a 10 f0       	push   $0xf0104a64
f01017b7:	e8 3a 16 00 00       	call   f0102df6 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01017bc:	b8 00 10 00 00       	mov    $0x1000,%eax
f01017c1:	e8 d9 f7 ff ff       	call   f0100f9f <boot_alloc>
f01017c6:	a3 6c 89 11 f0       	mov    %eax,0xf011896c
	memset(kern_pgdir, 0, PGSIZE);
f01017cb:	83 c4 0c             	add    $0xc,%esp
f01017ce:	68 00 10 00 00       	push   $0x1000
f01017d3:	6a 00                	push   $0x0
f01017d5:	50                   	push   %eax
f01017d6:	e8 d6 20 00 00       	call   f01038b1 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01017db:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01017e0:	83 c4 10             	add    $0x10,%esp
f01017e3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01017e8:	77 15                	ja     f01017ff <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01017ea:	50                   	push   %eax
f01017eb:	68 f4 49 10 f0       	push   $0xf01049f4
f01017f0:	68 98 00 00 00       	push   $0x98
f01017f5:	68 1b 46 10 f0       	push   $0xf010461b
f01017fa:	e8 8c e8 ff ff       	call   f010008b <_panic>
f01017ff:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101805:	83 ca 05             	or     $0x5,%edx
f0101808:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages*sizeof(struct PageInfo));
f010180e:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101813:	c1 e0 03             	shl    $0x3,%eax
f0101816:	e8 84 f7 ff ff       	call   f0100f9f <boot_alloc>
f010181b:	a3 70 89 11 f0       	mov    %eax,0xf0118970
	memset(pages,0,sizeof(npages*sizeof(struct PageInfo)));
f0101820:	83 ec 04             	sub    $0x4,%esp
f0101823:	6a 04                	push   $0x4
f0101825:	6a 00                	push   $0x0
f0101827:	50                   	push   %eax
f0101828:	e8 84 20 00 00       	call   f01038b1 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010182d:	e8 fc fa ff ff       	call   f010132e <page_init>

	check_page_free_list(1);
f0101832:	b8 01 00 00 00       	mov    $0x1,%eax
f0101837:	e8 2f f8 ff ff       	call   f010106b <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010183c:	83 c4 10             	add    $0x10,%esp
f010183f:	83 3d 70 89 11 f0 00 	cmpl   $0x0,0xf0118970
f0101846:	75 17                	jne    f010185f <mem_init+0x10e>
		panic("'pages' is a null pointer!");
f0101848:	83 ec 04             	sub    $0x4,%esp
f010184b:	68 dd 46 10 f0       	push   $0xf01046dd
f0101850:	68 63 02 00 00       	push   $0x263
f0101855:	68 1b 46 10 f0       	push   $0xf010461b
f010185a:	e8 2c e8 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010185f:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0101864:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101869:	eb 05                	jmp    f0101870 <mem_init+0x11f>
		++nfree;
f010186b:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010186e:	8b 00                	mov    (%eax),%eax
f0101870:	85 c0                	test   %eax,%eax
f0101872:	75 f7                	jne    f010186b <mem_init+0x11a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101874:	83 ec 0c             	sub    $0xc,%esp
f0101877:	6a 00                	push   $0x0
f0101879:	e8 b8 fb ff ff       	call   f0101436 <page_alloc>
f010187e:	89 c7                	mov    %eax,%edi
f0101880:	83 c4 10             	add    $0x10,%esp
f0101883:	85 c0                	test   %eax,%eax
f0101885:	75 19                	jne    f01018a0 <mem_init+0x14f>
f0101887:	68 f8 46 10 f0       	push   $0xf01046f8
f010188c:	68 41 46 10 f0       	push   $0xf0104641
f0101891:	68 6b 02 00 00       	push   $0x26b
f0101896:	68 1b 46 10 f0       	push   $0xf010461b
f010189b:	e8 eb e7 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01018a0:	83 ec 0c             	sub    $0xc,%esp
f01018a3:	6a 00                	push   $0x0
f01018a5:	e8 8c fb ff ff       	call   f0101436 <page_alloc>
f01018aa:	89 c6                	mov    %eax,%esi
f01018ac:	83 c4 10             	add    $0x10,%esp
f01018af:	85 c0                	test   %eax,%eax
f01018b1:	75 19                	jne    f01018cc <mem_init+0x17b>
f01018b3:	68 0e 47 10 f0       	push   $0xf010470e
f01018b8:	68 41 46 10 f0       	push   $0xf0104641
f01018bd:	68 6c 02 00 00       	push   $0x26c
f01018c2:	68 1b 46 10 f0       	push   $0xf010461b
f01018c7:	e8 bf e7 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01018cc:	83 ec 0c             	sub    $0xc,%esp
f01018cf:	6a 00                	push   $0x0
f01018d1:	e8 60 fb ff ff       	call   f0101436 <page_alloc>
f01018d6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018d9:	83 c4 10             	add    $0x10,%esp
f01018dc:	85 c0                	test   %eax,%eax
f01018de:	75 19                	jne    f01018f9 <mem_init+0x1a8>
f01018e0:	68 24 47 10 f0       	push   $0xf0104724
f01018e5:	68 41 46 10 f0       	push   $0xf0104641
f01018ea:	68 6d 02 00 00       	push   $0x26d
f01018ef:	68 1b 46 10 f0       	push   $0xf010461b
f01018f4:	e8 92 e7 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018f9:	39 f7                	cmp    %esi,%edi
f01018fb:	75 19                	jne    f0101916 <mem_init+0x1c5>
f01018fd:	68 3a 47 10 f0       	push   $0xf010473a
f0101902:	68 41 46 10 f0       	push   $0xf0104641
f0101907:	68 70 02 00 00       	push   $0x270
f010190c:	68 1b 46 10 f0       	push   $0xf010461b
f0101911:	e8 75 e7 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101916:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101919:	39 c6                	cmp    %eax,%esi
f010191b:	74 04                	je     f0101921 <mem_init+0x1d0>
f010191d:	39 c7                	cmp    %eax,%edi
f010191f:	75 19                	jne    f010193a <mem_init+0x1e9>
f0101921:	68 a0 4a 10 f0       	push   $0xf0104aa0
f0101926:	68 41 46 10 f0       	push   $0xf0104641
f010192b:	68 71 02 00 00       	push   $0x271
f0101930:	68 1b 46 10 f0       	push   $0xf010461b
f0101935:	e8 51 e7 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010193a:	8b 0d 70 89 11 f0    	mov    0xf0118970,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101940:	8b 15 68 89 11 f0    	mov    0xf0118968,%edx
f0101946:	c1 e2 0c             	shl    $0xc,%edx
f0101949:	89 f8                	mov    %edi,%eax
f010194b:	29 c8                	sub    %ecx,%eax
f010194d:	c1 f8 03             	sar    $0x3,%eax
f0101950:	c1 e0 0c             	shl    $0xc,%eax
f0101953:	39 d0                	cmp    %edx,%eax
f0101955:	72 19                	jb     f0101970 <mem_init+0x21f>
f0101957:	68 4c 47 10 f0       	push   $0xf010474c
f010195c:	68 41 46 10 f0       	push   $0xf0104641
f0101961:	68 72 02 00 00       	push   $0x272
f0101966:	68 1b 46 10 f0       	push   $0xf010461b
f010196b:	e8 1b e7 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101970:	89 f0                	mov    %esi,%eax
f0101972:	29 c8                	sub    %ecx,%eax
f0101974:	c1 f8 03             	sar    $0x3,%eax
f0101977:	c1 e0 0c             	shl    $0xc,%eax
f010197a:	39 c2                	cmp    %eax,%edx
f010197c:	77 19                	ja     f0101997 <mem_init+0x246>
f010197e:	68 69 47 10 f0       	push   $0xf0104769
f0101983:	68 41 46 10 f0       	push   $0xf0104641
f0101988:	68 73 02 00 00       	push   $0x273
f010198d:	68 1b 46 10 f0       	push   $0xf010461b
f0101992:	e8 f4 e6 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101997:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010199a:	29 c8                	sub    %ecx,%eax
f010199c:	c1 f8 03             	sar    $0x3,%eax
f010199f:	c1 e0 0c             	shl    $0xc,%eax
f01019a2:	39 c2                	cmp    %eax,%edx
f01019a4:	77 19                	ja     f01019bf <mem_init+0x26e>
f01019a6:	68 86 47 10 f0       	push   $0xf0104786
f01019ab:	68 41 46 10 f0       	push   $0xf0104641
f01019b0:	68 74 02 00 00       	push   $0x274
f01019b5:	68 1b 46 10 f0       	push   $0xf010461b
f01019ba:	e8 cc e6 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019bf:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f01019c4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01019c7:	c7 05 3c 85 11 f0 00 	movl   $0x0,0xf011853c
f01019ce:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019d1:	83 ec 0c             	sub    $0xc,%esp
f01019d4:	6a 00                	push   $0x0
f01019d6:	e8 5b fa ff ff       	call   f0101436 <page_alloc>
f01019db:	83 c4 10             	add    $0x10,%esp
f01019de:	85 c0                	test   %eax,%eax
f01019e0:	74 19                	je     f01019fb <mem_init+0x2aa>
f01019e2:	68 a3 47 10 f0       	push   $0xf01047a3
f01019e7:	68 41 46 10 f0       	push   $0xf0104641
f01019ec:	68 7b 02 00 00       	push   $0x27b
f01019f1:	68 1b 46 10 f0       	push   $0xf010461b
f01019f6:	e8 90 e6 ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01019fb:	83 ec 0c             	sub    $0xc,%esp
f01019fe:	57                   	push   %edi
f01019ff:	e8 a7 fa ff ff       	call   f01014ab <page_free>
	page_free(pp1);
f0101a04:	89 34 24             	mov    %esi,(%esp)
f0101a07:	e8 9f fa ff ff       	call   f01014ab <page_free>
	page_free(pp2);
f0101a0c:	83 c4 04             	add    $0x4,%esp
f0101a0f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a12:	e8 94 fa ff ff       	call   f01014ab <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a17:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a1e:	e8 13 fa ff ff       	call   f0101436 <page_alloc>
f0101a23:	89 c6                	mov    %eax,%esi
f0101a25:	83 c4 10             	add    $0x10,%esp
f0101a28:	85 c0                	test   %eax,%eax
f0101a2a:	75 19                	jne    f0101a45 <mem_init+0x2f4>
f0101a2c:	68 f8 46 10 f0       	push   $0xf01046f8
f0101a31:	68 41 46 10 f0       	push   $0xf0104641
f0101a36:	68 82 02 00 00       	push   $0x282
f0101a3b:	68 1b 46 10 f0       	push   $0xf010461b
f0101a40:	e8 46 e6 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101a45:	83 ec 0c             	sub    $0xc,%esp
f0101a48:	6a 00                	push   $0x0
f0101a4a:	e8 e7 f9 ff ff       	call   f0101436 <page_alloc>
f0101a4f:	89 c7                	mov    %eax,%edi
f0101a51:	83 c4 10             	add    $0x10,%esp
f0101a54:	85 c0                	test   %eax,%eax
f0101a56:	75 19                	jne    f0101a71 <mem_init+0x320>
f0101a58:	68 0e 47 10 f0       	push   $0xf010470e
f0101a5d:	68 41 46 10 f0       	push   $0xf0104641
f0101a62:	68 83 02 00 00       	push   $0x283
f0101a67:	68 1b 46 10 f0       	push   $0xf010461b
f0101a6c:	e8 1a e6 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101a71:	83 ec 0c             	sub    $0xc,%esp
f0101a74:	6a 00                	push   $0x0
f0101a76:	e8 bb f9 ff ff       	call   f0101436 <page_alloc>
f0101a7b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a7e:	83 c4 10             	add    $0x10,%esp
f0101a81:	85 c0                	test   %eax,%eax
f0101a83:	75 19                	jne    f0101a9e <mem_init+0x34d>
f0101a85:	68 24 47 10 f0       	push   $0xf0104724
f0101a8a:	68 41 46 10 f0       	push   $0xf0104641
f0101a8f:	68 84 02 00 00       	push   $0x284
f0101a94:	68 1b 46 10 f0       	push   $0xf010461b
f0101a99:	e8 ed e5 ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a9e:	39 fe                	cmp    %edi,%esi
f0101aa0:	75 19                	jne    f0101abb <mem_init+0x36a>
f0101aa2:	68 3a 47 10 f0       	push   $0xf010473a
f0101aa7:	68 41 46 10 f0       	push   $0xf0104641
f0101aac:	68 86 02 00 00       	push   $0x286
f0101ab1:	68 1b 46 10 f0       	push   $0xf010461b
f0101ab6:	e8 d0 e5 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101abb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101abe:	39 c7                	cmp    %eax,%edi
f0101ac0:	74 04                	je     f0101ac6 <mem_init+0x375>
f0101ac2:	39 c6                	cmp    %eax,%esi
f0101ac4:	75 19                	jne    f0101adf <mem_init+0x38e>
f0101ac6:	68 a0 4a 10 f0       	push   $0xf0104aa0
f0101acb:	68 41 46 10 f0       	push   $0xf0104641
f0101ad0:	68 87 02 00 00       	push   $0x287
f0101ad5:	68 1b 46 10 f0       	push   $0xf010461b
f0101ada:	e8 ac e5 ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101adf:	83 ec 0c             	sub    $0xc,%esp
f0101ae2:	6a 00                	push   $0x0
f0101ae4:	e8 4d f9 ff ff       	call   f0101436 <page_alloc>
f0101ae9:	83 c4 10             	add    $0x10,%esp
f0101aec:	85 c0                	test   %eax,%eax
f0101aee:	74 19                	je     f0101b09 <mem_init+0x3b8>
f0101af0:	68 a3 47 10 f0       	push   $0xf01047a3
f0101af5:	68 41 46 10 f0       	push   $0xf0104641
f0101afa:	68 88 02 00 00       	push   $0x288
f0101aff:	68 1b 46 10 f0       	push   $0xf010461b
f0101b04:	e8 82 e5 ff ff       	call   f010008b <_panic>
f0101b09:	89 f0                	mov    %esi,%eax
f0101b0b:	2b 05 70 89 11 f0    	sub    0xf0118970,%eax
f0101b11:	c1 f8 03             	sar    $0x3,%eax
f0101b14:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b17:	89 c2                	mov    %eax,%edx
f0101b19:	c1 ea 0c             	shr    $0xc,%edx
f0101b1c:	3b 15 68 89 11 f0    	cmp    0xf0118968,%edx
f0101b22:	72 12                	jb     f0101b36 <mem_init+0x3e5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b24:	50                   	push   %eax
f0101b25:	68 c4 43 10 f0       	push   $0xf01043c4
f0101b2a:	6a 52                	push   $0x52
f0101b2c:	68 27 46 10 f0       	push   $0xf0104627
f0101b31:	e8 55 e5 ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101b36:	83 ec 04             	sub    $0x4,%esp
f0101b39:	68 00 10 00 00       	push   $0x1000
f0101b3e:	6a 01                	push   $0x1
f0101b40:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b45:	50                   	push   %eax
f0101b46:	e8 66 1d 00 00       	call   f01038b1 <memset>
	page_free(pp0);
f0101b4b:	89 34 24             	mov    %esi,(%esp)
f0101b4e:	e8 58 f9 ff ff       	call   f01014ab <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101b53:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101b5a:	e8 d7 f8 ff ff       	call   f0101436 <page_alloc>
f0101b5f:	83 c4 10             	add    $0x10,%esp
f0101b62:	85 c0                	test   %eax,%eax
f0101b64:	75 19                	jne    f0101b7f <mem_init+0x42e>
f0101b66:	68 b2 47 10 f0       	push   $0xf01047b2
f0101b6b:	68 41 46 10 f0       	push   $0xf0104641
f0101b70:	68 8d 02 00 00       	push   $0x28d
f0101b75:	68 1b 46 10 f0       	push   $0xf010461b
f0101b7a:	e8 0c e5 ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101b7f:	39 c6                	cmp    %eax,%esi
f0101b81:	74 19                	je     f0101b9c <mem_init+0x44b>
f0101b83:	68 d0 47 10 f0       	push   $0xf01047d0
f0101b88:	68 41 46 10 f0       	push   $0xf0104641
f0101b8d:	68 8e 02 00 00       	push   $0x28e
f0101b92:	68 1b 46 10 f0       	push   $0xf010461b
f0101b97:	e8 ef e4 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b9c:	89 f0                	mov    %esi,%eax
f0101b9e:	2b 05 70 89 11 f0    	sub    0xf0118970,%eax
f0101ba4:	c1 f8 03             	sar    $0x3,%eax
f0101ba7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101baa:	89 c2                	mov    %eax,%edx
f0101bac:	c1 ea 0c             	shr    $0xc,%edx
f0101baf:	3b 15 68 89 11 f0    	cmp    0xf0118968,%edx
f0101bb5:	72 12                	jb     f0101bc9 <mem_init+0x478>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101bb7:	50                   	push   %eax
f0101bb8:	68 c4 43 10 f0       	push   $0xf01043c4
f0101bbd:	6a 52                	push   $0x52
f0101bbf:	68 27 46 10 f0       	push   $0xf0104627
f0101bc4:	e8 c2 e4 ff ff       	call   f010008b <_panic>
f0101bc9:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101bcf:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101bd5:	80 38 00             	cmpb   $0x0,(%eax)
f0101bd8:	74 19                	je     f0101bf3 <mem_init+0x4a2>
f0101bda:	68 e0 47 10 f0       	push   $0xf01047e0
f0101bdf:	68 41 46 10 f0       	push   $0xf0104641
f0101be4:	68 91 02 00 00       	push   $0x291
f0101be9:	68 1b 46 10 f0       	push   $0xf010461b
f0101bee:	e8 98 e4 ff ff       	call   f010008b <_panic>
f0101bf3:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101bf6:	39 d0                	cmp    %edx,%eax
f0101bf8:	75 db                	jne    f0101bd5 <mem_init+0x484>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101bfa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bfd:	a3 3c 85 11 f0       	mov    %eax,0xf011853c

	// free the pages we took
	page_free(pp0);
f0101c02:	83 ec 0c             	sub    $0xc,%esp
f0101c05:	56                   	push   %esi
f0101c06:	e8 a0 f8 ff ff       	call   f01014ab <page_free>
	page_free(pp1);
f0101c0b:	89 3c 24             	mov    %edi,(%esp)
f0101c0e:	e8 98 f8 ff ff       	call   f01014ab <page_free>
	page_free(pp2);
f0101c13:	83 c4 04             	add    $0x4,%esp
f0101c16:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c19:	e8 8d f8 ff ff       	call   f01014ab <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101c1e:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0101c23:	83 c4 10             	add    $0x10,%esp
f0101c26:	eb 05                	jmp    f0101c2d <mem_init+0x4dc>
		--nfree;
f0101c28:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101c2b:	8b 00                	mov    (%eax),%eax
f0101c2d:	85 c0                	test   %eax,%eax
f0101c2f:	75 f7                	jne    f0101c28 <mem_init+0x4d7>
		--nfree;
	assert(nfree == 0);
f0101c31:	85 db                	test   %ebx,%ebx
f0101c33:	74 19                	je     f0101c4e <mem_init+0x4fd>
f0101c35:	68 ea 47 10 f0       	push   $0xf01047ea
f0101c3a:	68 41 46 10 f0       	push   $0xf0104641
f0101c3f:	68 9e 02 00 00       	push   $0x29e
f0101c44:	68 1b 46 10 f0       	push   $0xf010461b
f0101c49:	e8 3d e4 ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101c4e:	83 ec 0c             	sub    $0xc,%esp
f0101c51:	68 c0 4a 10 f0       	push   $0xf0104ac0
f0101c56:	e8 9b 11 00 00       	call   f0102df6 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101c5b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c62:	e8 cf f7 ff ff       	call   f0101436 <page_alloc>
f0101c67:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101c6a:	83 c4 10             	add    $0x10,%esp
f0101c6d:	85 c0                	test   %eax,%eax
f0101c6f:	75 19                	jne    f0101c8a <mem_init+0x539>
f0101c71:	68 f8 46 10 f0       	push   $0xf01046f8
f0101c76:	68 41 46 10 f0       	push   $0xf0104641
f0101c7b:	68 f7 02 00 00       	push   $0x2f7
f0101c80:	68 1b 46 10 f0       	push   $0xf010461b
f0101c85:	e8 01 e4 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101c8a:	83 ec 0c             	sub    $0xc,%esp
f0101c8d:	6a 00                	push   $0x0
f0101c8f:	e8 a2 f7 ff ff       	call   f0101436 <page_alloc>
f0101c94:	89 c3                	mov    %eax,%ebx
f0101c96:	83 c4 10             	add    $0x10,%esp
f0101c99:	85 c0                	test   %eax,%eax
f0101c9b:	75 19                	jne    f0101cb6 <mem_init+0x565>
f0101c9d:	68 0e 47 10 f0       	push   $0xf010470e
f0101ca2:	68 41 46 10 f0       	push   $0xf0104641
f0101ca7:	68 f8 02 00 00       	push   $0x2f8
f0101cac:	68 1b 46 10 f0       	push   $0xf010461b
f0101cb1:	e8 d5 e3 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101cb6:	83 ec 0c             	sub    $0xc,%esp
f0101cb9:	6a 00                	push   $0x0
f0101cbb:	e8 76 f7 ff ff       	call   f0101436 <page_alloc>
f0101cc0:	89 c6                	mov    %eax,%esi
f0101cc2:	83 c4 10             	add    $0x10,%esp
f0101cc5:	85 c0                	test   %eax,%eax
f0101cc7:	75 19                	jne    f0101ce2 <mem_init+0x591>
f0101cc9:	68 24 47 10 f0       	push   $0xf0104724
f0101cce:	68 41 46 10 f0       	push   $0xf0104641
f0101cd3:	68 f9 02 00 00       	push   $0x2f9
f0101cd8:	68 1b 46 10 f0       	push   $0xf010461b
f0101cdd:	e8 a9 e3 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101ce2:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101ce5:	75 19                	jne    f0101d00 <mem_init+0x5af>
f0101ce7:	68 3a 47 10 f0       	push   $0xf010473a
f0101cec:	68 41 46 10 f0       	push   $0xf0104641
f0101cf1:	68 fc 02 00 00       	push   $0x2fc
f0101cf6:	68 1b 46 10 f0       	push   $0xf010461b
f0101cfb:	e8 8b e3 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101d00:	39 c3                	cmp    %eax,%ebx
f0101d02:	74 05                	je     f0101d09 <mem_init+0x5b8>
f0101d04:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101d07:	75 19                	jne    f0101d22 <mem_init+0x5d1>
f0101d09:	68 a0 4a 10 f0       	push   $0xf0104aa0
f0101d0e:	68 41 46 10 f0       	push   $0xf0104641
f0101d13:	68 fd 02 00 00       	push   $0x2fd
f0101d18:	68 1b 46 10 f0       	push   $0xf010461b
f0101d1d:	e8 69 e3 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101d22:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0101d27:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101d2a:	c7 05 3c 85 11 f0 00 	movl   $0x0,0xf011853c
f0101d31:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101d34:	83 ec 0c             	sub    $0xc,%esp
f0101d37:	6a 00                	push   $0x0
f0101d39:	e8 f8 f6 ff ff       	call   f0101436 <page_alloc>
f0101d3e:	83 c4 10             	add    $0x10,%esp
f0101d41:	85 c0                	test   %eax,%eax
f0101d43:	74 19                	je     f0101d5e <mem_init+0x60d>
f0101d45:	68 a3 47 10 f0       	push   $0xf01047a3
f0101d4a:	68 41 46 10 f0       	push   $0xf0104641
f0101d4f:	68 04 03 00 00       	push   $0x304
f0101d54:	68 1b 46 10 f0       	push   $0xf010461b
f0101d59:	e8 2d e3 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101d5e:	83 ec 04             	sub    $0x4,%esp
f0101d61:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101d64:	50                   	push   %eax
f0101d65:	6a 00                	push   $0x0
f0101d67:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0101d6d:	e8 99 f8 ff ff       	call   f010160b <page_lookup>
f0101d72:	83 c4 10             	add    $0x10,%esp
f0101d75:	85 c0                	test   %eax,%eax
f0101d77:	74 19                	je     f0101d92 <mem_init+0x641>
f0101d79:	68 e0 4a 10 f0       	push   $0xf0104ae0
f0101d7e:	68 41 46 10 f0       	push   $0xf0104641
f0101d83:	68 07 03 00 00       	push   $0x307
f0101d88:	68 1b 46 10 f0       	push   $0xf010461b
f0101d8d:	e8 f9 e2 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101d92:	6a 02                	push   $0x2
f0101d94:	6a 00                	push   $0x0
f0101d96:	53                   	push   %ebx
f0101d97:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0101d9d:	e8 15 f9 ff ff       	call   f01016b7 <page_insert>
f0101da2:	83 c4 10             	add    $0x10,%esp
f0101da5:	85 c0                	test   %eax,%eax
f0101da7:	78 19                	js     f0101dc2 <mem_init+0x671>
f0101da9:	68 18 4b 10 f0       	push   $0xf0104b18
f0101dae:	68 41 46 10 f0       	push   $0xf0104641
f0101db3:	68 0a 03 00 00       	push   $0x30a
f0101db8:	68 1b 46 10 f0       	push   $0xf010461b
f0101dbd:	e8 c9 e2 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101dc2:	83 ec 0c             	sub    $0xc,%esp
f0101dc5:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101dc8:	e8 de f6 ff ff       	call   f01014ab <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101dcd:	6a 02                	push   $0x2
f0101dcf:	6a 00                	push   $0x0
f0101dd1:	53                   	push   %ebx
f0101dd2:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0101dd8:	e8 da f8 ff ff       	call   f01016b7 <page_insert>
f0101ddd:	83 c4 20             	add    $0x20,%esp
f0101de0:	85 c0                	test   %eax,%eax
f0101de2:	74 19                	je     f0101dfd <mem_init+0x6ac>
f0101de4:	68 48 4b 10 f0       	push   $0xf0104b48
f0101de9:	68 41 46 10 f0       	push   $0xf0104641
f0101dee:	68 0e 03 00 00       	push   $0x30e
f0101df3:	68 1b 46 10 f0       	push   $0xf010461b
f0101df8:	e8 8e e2 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101dfd:	8b 3d 6c 89 11 f0    	mov    0xf011896c,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e03:	a1 70 89 11 f0       	mov    0xf0118970,%eax
f0101e08:	89 c1                	mov    %eax,%ecx
f0101e0a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e0d:	8b 17                	mov    (%edi),%edx
f0101e0f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e15:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e18:	29 c8                	sub    %ecx,%eax
f0101e1a:	c1 f8 03             	sar    $0x3,%eax
f0101e1d:	c1 e0 0c             	shl    $0xc,%eax
f0101e20:	39 c2                	cmp    %eax,%edx
f0101e22:	74 19                	je     f0101e3d <mem_init+0x6ec>
f0101e24:	68 78 4b 10 f0       	push   $0xf0104b78
f0101e29:	68 41 46 10 f0       	push   $0xf0104641
f0101e2e:	68 0f 03 00 00       	push   $0x30f
f0101e33:	68 1b 46 10 f0       	push   $0xf010461b
f0101e38:	e8 4e e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101e3d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e42:	89 f8                	mov    %edi,%eax
f0101e44:	e8 be f1 ff ff       	call   f0101007 <check_va2pa>
f0101e49:	89 da                	mov    %ebx,%edx
f0101e4b:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101e4e:	c1 fa 03             	sar    $0x3,%edx
f0101e51:	c1 e2 0c             	shl    $0xc,%edx
f0101e54:	39 d0                	cmp    %edx,%eax
f0101e56:	74 19                	je     f0101e71 <mem_init+0x720>
f0101e58:	68 a0 4b 10 f0       	push   $0xf0104ba0
f0101e5d:	68 41 46 10 f0       	push   $0xf0104641
f0101e62:	68 10 03 00 00       	push   $0x310
f0101e67:	68 1b 46 10 f0       	push   $0xf010461b
f0101e6c:	e8 1a e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101e71:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101e76:	74 19                	je     f0101e91 <mem_init+0x740>
f0101e78:	68 f5 47 10 f0       	push   $0xf01047f5
f0101e7d:	68 41 46 10 f0       	push   $0xf0104641
f0101e82:	68 11 03 00 00       	push   $0x311
f0101e87:	68 1b 46 10 f0       	push   $0xf010461b
f0101e8c:	e8 fa e1 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101e91:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e94:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e99:	74 19                	je     f0101eb4 <mem_init+0x763>
f0101e9b:	68 06 48 10 f0       	push   $0xf0104806
f0101ea0:	68 41 46 10 f0       	push   $0xf0104641
f0101ea5:	68 12 03 00 00       	push   $0x312
f0101eaa:	68 1b 46 10 f0       	push   $0xf010461b
f0101eaf:	e8 d7 e1 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101eb4:	6a 02                	push   $0x2
f0101eb6:	68 00 10 00 00       	push   $0x1000
f0101ebb:	56                   	push   %esi
f0101ebc:	57                   	push   %edi
f0101ebd:	e8 f5 f7 ff ff       	call   f01016b7 <page_insert>
f0101ec2:	83 c4 10             	add    $0x10,%esp
f0101ec5:	85 c0                	test   %eax,%eax
f0101ec7:	74 19                	je     f0101ee2 <mem_init+0x791>
f0101ec9:	68 d0 4b 10 f0       	push   $0xf0104bd0
f0101ece:	68 41 46 10 f0       	push   $0xf0104641
f0101ed3:	68 15 03 00 00       	push   $0x315
f0101ed8:	68 1b 46 10 f0       	push   $0xf010461b
f0101edd:	e8 a9 e1 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ee2:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ee7:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0101eec:	e8 16 f1 ff ff       	call   f0101007 <check_va2pa>
f0101ef1:	89 f2                	mov    %esi,%edx
f0101ef3:	2b 15 70 89 11 f0    	sub    0xf0118970,%edx
f0101ef9:	c1 fa 03             	sar    $0x3,%edx
f0101efc:	c1 e2 0c             	shl    $0xc,%edx
f0101eff:	39 d0                	cmp    %edx,%eax
f0101f01:	74 19                	je     f0101f1c <mem_init+0x7cb>
f0101f03:	68 0c 4c 10 f0       	push   $0xf0104c0c
f0101f08:	68 41 46 10 f0       	push   $0xf0104641
f0101f0d:	68 16 03 00 00       	push   $0x316
f0101f12:	68 1b 46 10 f0       	push   $0xf010461b
f0101f17:	e8 6f e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101f1c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f21:	74 19                	je     f0101f3c <mem_init+0x7eb>
f0101f23:	68 17 48 10 f0       	push   $0xf0104817
f0101f28:	68 41 46 10 f0       	push   $0xf0104641
f0101f2d:	68 17 03 00 00       	push   $0x317
f0101f32:	68 1b 46 10 f0       	push   $0xf010461b
f0101f37:	e8 4f e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f3c:	83 ec 0c             	sub    $0xc,%esp
f0101f3f:	6a 00                	push   $0x0
f0101f41:	e8 f0 f4 ff ff       	call   f0101436 <page_alloc>
f0101f46:	83 c4 10             	add    $0x10,%esp
f0101f49:	85 c0                	test   %eax,%eax
f0101f4b:	74 19                	je     f0101f66 <mem_init+0x815>
f0101f4d:	68 a3 47 10 f0       	push   $0xf01047a3
f0101f52:	68 41 46 10 f0       	push   $0xf0104641
f0101f57:	68 1a 03 00 00       	push   $0x31a
f0101f5c:	68 1b 46 10 f0       	push   $0xf010461b
f0101f61:	e8 25 e1 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f66:	6a 02                	push   $0x2
f0101f68:	68 00 10 00 00       	push   $0x1000
f0101f6d:	56                   	push   %esi
f0101f6e:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0101f74:	e8 3e f7 ff ff       	call   f01016b7 <page_insert>
f0101f79:	83 c4 10             	add    $0x10,%esp
f0101f7c:	85 c0                	test   %eax,%eax
f0101f7e:	74 19                	je     f0101f99 <mem_init+0x848>
f0101f80:	68 d0 4b 10 f0       	push   $0xf0104bd0
f0101f85:	68 41 46 10 f0       	push   $0xf0104641
f0101f8a:	68 1d 03 00 00       	push   $0x31d
f0101f8f:	68 1b 46 10 f0       	push   $0xf010461b
f0101f94:	e8 f2 e0 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f99:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f9e:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0101fa3:	e8 5f f0 ff ff       	call   f0101007 <check_va2pa>
f0101fa8:	89 f2                	mov    %esi,%edx
f0101faa:	2b 15 70 89 11 f0    	sub    0xf0118970,%edx
f0101fb0:	c1 fa 03             	sar    $0x3,%edx
f0101fb3:	c1 e2 0c             	shl    $0xc,%edx
f0101fb6:	39 d0                	cmp    %edx,%eax
f0101fb8:	74 19                	je     f0101fd3 <mem_init+0x882>
f0101fba:	68 0c 4c 10 f0       	push   $0xf0104c0c
f0101fbf:	68 41 46 10 f0       	push   $0xf0104641
f0101fc4:	68 1e 03 00 00       	push   $0x31e
f0101fc9:	68 1b 46 10 f0       	push   $0xf010461b
f0101fce:	e8 b8 e0 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101fd3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fd8:	74 19                	je     f0101ff3 <mem_init+0x8a2>
f0101fda:	68 17 48 10 f0       	push   $0xf0104817
f0101fdf:	68 41 46 10 f0       	push   $0xf0104641
f0101fe4:	68 1f 03 00 00       	push   $0x31f
f0101fe9:	68 1b 46 10 f0       	push   $0xf010461b
f0101fee:	e8 98 e0 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ff3:	83 ec 0c             	sub    $0xc,%esp
f0101ff6:	6a 00                	push   $0x0
f0101ff8:	e8 39 f4 ff ff       	call   f0101436 <page_alloc>
f0101ffd:	83 c4 10             	add    $0x10,%esp
f0102000:	85 c0                	test   %eax,%eax
f0102002:	74 19                	je     f010201d <mem_init+0x8cc>
f0102004:	68 a3 47 10 f0       	push   $0xf01047a3
f0102009:	68 41 46 10 f0       	push   $0xf0104641
f010200e:	68 23 03 00 00       	push   $0x323
f0102013:	68 1b 46 10 f0       	push   $0xf010461b
f0102018:	e8 6e e0 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010201d:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
f0102023:	8b 02                	mov    (%edx),%eax
f0102025:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010202a:	89 c1                	mov    %eax,%ecx
f010202c:	c1 e9 0c             	shr    $0xc,%ecx
f010202f:	3b 0d 68 89 11 f0    	cmp    0xf0118968,%ecx
f0102035:	72 15                	jb     f010204c <mem_init+0x8fb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102037:	50                   	push   %eax
f0102038:	68 c4 43 10 f0       	push   $0xf01043c4
f010203d:	68 26 03 00 00       	push   $0x326
f0102042:	68 1b 46 10 f0       	push   $0xf010461b
f0102047:	e8 3f e0 ff ff       	call   f010008b <_panic>
f010204c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102051:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102054:	83 ec 04             	sub    $0x4,%esp
f0102057:	6a 00                	push   $0x0
f0102059:	68 00 10 00 00       	push   $0x1000
f010205e:	52                   	push   %edx
f010205f:	e8 a9 f4 ff ff       	call   f010150d <pgdir_walk>
f0102064:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102067:	8d 51 04             	lea    0x4(%ecx),%edx
f010206a:	83 c4 10             	add    $0x10,%esp
f010206d:	39 d0                	cmp    %edx,%eax
f010206f:	74 19                	je     f010208a <mem_init+0x939>
f0102071:	68 3c 4c 10 f0       	push   $0xf0104c3c
f0102076:	68 41 46 10 f0       	push   $0xf0104641
f010207b:	68 27 03 00 00       	push   $0x327
f0102080:	68 1b 46 10 f0       	push   $0xf010461b
f0102085:	e8 01 e0 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010208a:	6a 06                	push   $0x6
f010208c:	68 00 10 00 00       	push   $0x1000
f0102091:	56                   	push   %esi
f0102092:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0102098:	e8 1a f6 ff ff       	call   f01016b7 <page_insert>
f010209d:	83 c4 10             	add    $0x10,%esp
f01020a0:	85 c0                	test   %eax,%eax
f01020a2:	74 19                	je     f01020bd <mem_init+0x96c>
f01020a4:	68 7c 4c 10 f0       	push   $0xf0104c7c
f01020a9:	68 41 46 10 f0       	push   $0xf0104641
f01020ae:	68 2a 03 00 00       	push   $0x32a
f01020b3:	68 1b 46 10 f0       	push   $0xf010461b
f01020b8:	e8 ce df ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01020bd:	8b 3d 6c 89 11 f0    	mov    0xf011896c,%edi
f01020c3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020c8:	89 f8                	mov    %edi,%eax
f01020ca:	e8 38 ef ff ff       	call   f0101007 <check_va2pa>
f01020cf:	89 f2                	mov    %esi,%edx
f01020d1:	2b 15 70 89 11 f0    	sub    0xf0118970,%edx
f01020d7:	c1 fa 03             	sar    $0x3,%edx
f01020da:	c1 e2 0c             	shl    $0xc,%edx
f01020dd:	39 d0                	cmp    %edx,%eax
f01020df:	74 19                	je     f01020fa <mem_init+0x9a9>
f01020e1:	68 0c 4c 10 f0       	push   $0xf0104c0c
f01020e6:	68 41 46 10 f0       	push   $0xf0104641
f01020eb:	68 2b 03 00 00       	push   $0x32b
f01020f0:	68 1b 46 10 f0       	push   $0xf010461b
f01020f5:	e8 91 df ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01020fa:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01020ff:	74 19                	je     f010211a <mem_init+0x9c9>
f0102101:	68 17 48 10 f0       	push   $0xf0104817
f0102106:	68 41 46 10 f0       	push   $0xf0104641
f010210b:	68 2c 03 00 00       	push   $0x32c
f0102110:	68 1b 46 10 f0       	push   $0xf010461b
f0102115:	e8 71 df ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f010211a:	83 ec 04             	sub    $0x4,%esp
f010211d:	6a 00                	push   $0x0
f010211f:	68 00 10 00 00       	push   $0x1000
f0102124:	57                   	push   %edi
f0102125:	e8 e3 f3 ff ff       	call   f010150d <pgdir_walk>
f010212a:	83 c4 10             	add    $0x10,%esp
f010212d:	f6 00 04             	testb  $0x4,(%eax)
f0102130:	75 19                	jne    f010214b <mem_init+0x9fa>
f0102132:	68 bc 4c 10 f0       	push   $0xf0104cbc
f0102137:	68 41 46 10 f0       	push   $0xf0104641
f010213c:	68 2d 03 00 00       	push   $0x32d
f0102141:	68 1b 46 10 f0       	push   $0xf010461b
f0102146:	e8 40 df ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010214b:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0102150:	f6 00 04             	testb  $0x4,(%eax)
f0102153:	75 19                	jne    f010216e <mem_init+0xa1d>
f0102155:	68 28 48 10 f0       	push   $0xf0104828
f010215a:	68 41 46 10 f0       	push   $0xf0104641
f010215f:	68 2e 03 00 00       	push   $0x32e
f0102164:	68 1b 46 10 f0       	push   $0xf010461b
f0102169:	e8 1d df ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010216e:	6a 02                	push   $0x2
f0102170:	68 00 10 00 00       	push   $0x1000
f0102175:	56                   	push   %esi
f0102176:	50                   	push   %eax
f0102177:	e8 3b f5 ff ff       	call   f01016b7 <page_insert>
f010217c:	83 c4 10             	add    $0x10,%esp
f010217f:	85 c0                	test   %eax,%eax
f0102181:	74 19                	je     f010219c <mem_init+0xa4b>
f0102183:	68 d0 4b 10 f0       	push   $0xf0104bd0
f0102188:	68 41 46 10 f0       	push   $0xf0104641
f010218d:	68 31 03 00 00       	push   $0x331
f0102192:	68 1b 46 10 f0       	push   $0xf010461b
f0102197:	e8 ef de ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010219c:	83 ec 04             	sub    $0x4,%esp
f010219f:	6a 00                	push   $0x0
f01021a1:	68 00 10 00 00       	push   $0x1000
f01021a6:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f01021ac:	e8 5c f3 ff ff       	call   f010150d <pgdir_walk>
f01021b1:	83 c4 10             	add    $0x10,%esp
f01021b4:	f6 00 02             	testb  $0x2,(%eax)
f01021b7:	75 19                	jne    f01021d2 <mem_init+0xa81>
f01021b9:	68 f0 4c 10 f0       	push   $0xf0104cf0
f01021be:	68 41 46 10 f0       	push   $0xf0104641
f01021c3:	68 32 03 00 00       	push   $0x332
f01021c8:	68 1b 46 10 f0       	push   $0xf010461b
f01021cd:	e8 b9 de ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01021d2:	83 ec 04             	sub    $0x4,%esp
f01021d5:	6a 00                	push   $0x0
f01021d7:	68 00 10 00 00       	push   $0x1000
f01021dc:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f01021e2:	e8 26 f3 ff ff       	call   f010150d <pgdir_walk>
f01021e7:	83 c4 10             	add    $0x10,%esp
f01021ea:	f6 00 04             	testb  $0x4,(%eax)
f01021ed:	74 19                	je     f0102208 <mem_init+0xab7>
f01021ef:	68 24 4d 10 f0       	push   $0xf0104d24
f01021f4:	68 41 46 10 f0       	push   $0xf0104641
f01021f9:	68 33 03 00 00       	push   $0x333
f01021fe:	68 1b 46 10 f0       	push   $0xf010461b
f0102203:	e8 83 de ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102208:	6a 02                	push   $0x2
f010220a:	68 00 00 40 00       	push   $0x400000
f010220f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102212:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0102218:	e8 9a f4 ff ff       	call   f01016b7 <page_insert>
f010221d:	83 c4 10             	add    $0x10,%esp
f0102220:	85 c0                	test   %eax,%eax
f0102222:	78 19                	js     f010223d <mem_init+0xaec>
f0102224:	68 5c 4d 10 f0       	push   $0xf0104d5c
f0102229:	68 41 46 10 f0       	push   $0xf0104641
f010222e:	68 36 03 00 00       	push   $0x336
f0102233:	68 1b 46 10 f0       	push   $0xf010461b
f0102238:	e8 4e de ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010223d:	6a 02                	push   $0x2
f010223f:	68 00 10 00 00       	push   $0x1000
f0102244:	53                   	push   %ebx
f0102245:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f010224b:	e8 67 f4 ff ff       	call   f01016b7 <page_insert>
f0102250:	83 c4 10             	add    $0x10,%esp
f0102253:	85 c0                	test   %eax,%eax
f0102255:	74 19                	je     f0102270 <mem_init+0xb1f>
f0102257:	68 94 4d 10 f0       	push   $0xf0104d94
f010225c:	68 41 46 10 f0       	push   $0xf0104641
f0102261:	68 39 03 00 00       	push   $0x339
f0102266:	68 1b 46 10 f0       	push   $0xf010461b
f010226b:	e8 1b de ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102270:	83 ec 04             	sub    $0x4,%esp
f0102273:	6a 00                	push   $0x0
f0102275:	68 00 10 00 00       	push   $0x1000
f010227a:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0102280:	e8 88 f2 ff ff       	call   f010150d <pgdir_walk>
f0102285:	83 c4 10             	add    $0x10,%esp
f0102288:	f6 00 04             	testb  $0x4,(%eax)
f010228b:	74 19                	je     f01022a6 <mem_init+0xb55>
f010228d:	68 24 4d 10 f0       	push   $0xf0104d24
f0102292:	68 41 46 10 f0       	push   $0xf0104641
f0102297:	68 3a 03 00 00       	push   $0x33a
f010229c:	68 1b 46 10 f0       	push   $0xf010461b
f01022a1:	e8 e5 dd ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01022a6:	8b 3d 6c 89 11 f0    	mov    0xf011896c,%edi
f01022ac:	ba 00 00 00 00       	mov    $0x0,%edx
f01022b1:	89 f8                	mov    %edi,%eax
f01022b3:	e8 4f ed ff ff       	call   f0101007 <check_va2pa>
f01022b8:	89 c1                	mov    %eax,%ecx
f01022ba:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01022bd:	89 d8                	mov    %ebx,%eax
f01022bf:	2b 05 70 89 11 f0    	sub    0xf0118970,%eax
f01022c5:	c1 f8 03             	sar    $0x3,%eax
f01022c8:	c1 e0 0c             	shl    $0xc,%eax
f01022cb:	39 c1                	cmp    %eax,%ecx
f01022cd:	74 19                	je     f01022e8 <mem_init+0xb97>
f01022cf:	68 d0 4d 10 f0       	push   $0xf0104dd0
f01022d4:	68 41 46 10 f0       	push   $0xf0104641
f01022d9:	68 3d 03 00 00       	push   $0x33d
f01022de:	68 1b 46 10 f0       	push   $0xf010461b
f01022e3:	e8 a3 dd ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01022e8:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022ed:	89 f8                	mov    %edi,%eax
f01022ef:	e8 13 ed ff ff       	call   f0101007 <check_va2pa>
f01022f4:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01022f7:	74 19                	je     f0102312 <mem_init+0xbc1>
f01022f9:	68 fc 4d 10 f0       	push   $0xf0104dfc
f01022fe:	68 41 46 10 f0       	push   $0xf0104641
f0102303:	68 3e 03 00 00       	push   $0x33e
f0102308:	68 1b 46 10 f0       	push   $0xf010461b
f010230d:	e8 79 dd ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102312:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0102317:	74 19                	je     f0102332 <mem_init+0xbe1>
f0102319:	68 3e 48 10 f0       	push   $0xf010483e
f010231e:	68 41 46 10 f0       	push   $0xf0104641
f0102323:	68 40 03 00 00       	push   $0x340
f0102328:	68 1b 46 10 f0       	push   $0xf010461b
f010232d:	e8 59 dd ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0102332:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102337:	74 19                	je     f0102352 <mem_init+0xc01>
f0102339:	68 4f 48 10 f0       	push   $0xf010484f
f010233e:	68 41 46 10 f0       	push   $0xf0104641
f0102343:	68 41 03 00 00       	push   $0x341
f0102348:	68 1b 46 10 f0       	push   $0xf010461b
f010234d:	e8 39 dd ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102352:	83 ec 0c             	sub    $0xc,%esp
f0102355:	6a 00                	push   $0x0
f0102357:	e8 da f0 ff ff       	call   f0101436 <page_alloc>
f010235c:	83 c4 10             	add    $0x10,%esp
f010235f:	85 c0                	test   %eax,%eax
f0102361:	74 04                	je     f0102367 <mem_init+0xc16>
f0102363:	39 c6                	cmp    %eax,%esi
f0102365:	74 19                	je     f0102380 <mem_init+0xc2f>
f0102367:	68 2c 4e 10 f0       	push   $0xf0104e2c
f010236c:	68 41 46 10 f0       	push   $0xf0104641
f0102371:	68 44 03 00 00       	push   $0x344
f0102376:	68 1b 46 10 f0       	push   $0xf010461b
f010237b:	e8 0b dd ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102380:	83 ec 08             	sub    $0x8,%esp
f0102383:	6a 00                	push   $0x0
f0102385:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f010238b:	e8 e1 f2 ff ff       	call   f0101671 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102390:	8b 3d 6c 89 11 f0    	mov    0xf011896c,%edi
f0102396:	ba 00 00 00 00       	mov    $0x0,%edx
f010239b:	89 f8                	mov    %edi,%eax
f010239d:	e8 65 ec ff ff       	call   f0101007 <check_va2pa>
f01023a2:	83 c4 10             	add    $0x10,%esp
f01023a5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023a8:	74 19                	je     f01023c3 <mem_init+0xc72>
f01023aa:	68 50 4e 10 f0       	push   $0xf0104e50
f01023af:	68 41 46 10 f0       	push   $0xf0104641
f01023b4:	68 48 03 00 00       	push   $0x348
f01023b9:	68 1b 46 10 f0       	push   $0xf010461b
f01023be:	e8 c8 dc ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01023c3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01023c8:	89 f8                	mov    %edi,%eax
f01023ca:	e8 38 ec ff ff       	call   f0101007 <check_va2pa>
f01023cf:	89 da                	mov    %ebx,%edx
f01023d1:	2b 15 70 89 11 f0    	sub    0xf0118970,%edx
f01023d7:	c1 fa 03             	sar    $0x3,%edx
f01023da:	c1 e2 0c             	shl    $0xc,%edx
f01023dd:	39 d0                	cmp    %edx,%eax
f01023df:	74 19                	je     f01023fa <mem_init+0xca9>
f01023e1:	68 fc 4d 10 f0       	push   $0xf0104dfc
f01023e6:	68 41 46 10 f0       	push   $0xf0104641
f01023eb:	68 49 03 00 00       	push   $0x349
f01023f0:	68 1b 46 10 f0       	push   $0xf010461b
f01023f5:	e8 91 dc ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01023fa:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01023ff:	74 19                	je     f010241a <mem_init+0xcc9>
f0102401:	68 f5 47 10 f0       	push   $0xf01047f5
f0102406:	68 41 46 10 f0       	push   $0xf0104641
f010240b:	68 4a 03 00 00       	push   $0x34a
f0102410:	68 1b 46 10 f0       	push   $0xf010461b
f0102415:	e8 71 dc ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f010241a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010241f:	74 19                	je     f010243a <mem_init+0xce9>
f0102421:	68 4f 48 10 f0       	push   $0xf010484f
f0102426:	68 41 46 10 f0       	push   $0xf0104641
f010242b:	68 4b 03 00 00       	push   $0x34b
f0102430:	68 1b 46 10 f0       	push   $0xf010461b
f0102435:	e8 51 dc ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010243a:	6a 00                	push   $0x0
f010243c:	68 00 10 00 00       	push   $0x1000
f0102441:	53                   	push   %ebx
f0102442:	57                   	push   %edi
f0102443:	e8 6f f2 ff ff       	call   f01016b7 <page_insert>
f0102448:	83 c4 10             	add    $0x10,%esp
f010244b:	85 c0                	test   %eax,%eax
f010244d:	74 19                	je     f0102468 <mem_init+0xd17>
f010244f:	68 74 4e 10 f0       	push   $0xf0104e74
f0102454:	68 41 46 10 f0       	push   $0xf0104641
f0102459:	68 4e 03 00 00       	push   $0x34e
f010245e:	68 1b 46 10 f0       	push   $0xf010461b
f0102463:	e8 23 dc ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0102468:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010246d:	75 19                	jne    f0102488 <mem_init+0xd37>
f010246f:	68 60 48 10 f0       	push   $0xf0104860
f0102474:	68 41 46 10 f0       	push   $0xf0104641
f0102479:	68 4f 03 00 00       	push   $0x34f
f010247e:	68 1b 46 10 f0       	push   $0xf010461b
f0102483:	e8 03 dc ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0102488:	83 3b 00             	cmpl   $0x0,(%ebx)
f010248b:	74 19                	je     f01024a6 <mem_init+0xd55>
f010248d:	68 6c 48 10 f0       	push   $0xf010486c
f0102492:	68 41 46 10 f0       	push   $0xf0104641
f0102497:	68 50 03 00 00       	push   $0x350
f010249c:	68 1b 46 10 f0       	push   $0xf010461b
f01024a1:	e8 e5 db ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01024a6:	83 ec 08             	sub    $0x8,%esp
f01024a9:	68 00 10 00 00       	push   $0x1000
f01024ae:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f01024b4:	e8 b8 f1 ff ff       	call   f0101671 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01024b9:	8b 3d 6c 89 11 f0    	mov    0xf011896c,%edi
f01024bf:	ba 00 00 00 00       	mov    $0x0,%edx
f01024c4:	89 f8                	mov    %edi,%eax
f01024c6:	e8 3c eb ff ff       	call   f0101007 <check_va2pa>
f01024cb:	83 c4 10             	add    $0x10,%esp
f01024ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024d1:	74 19                	je     f01024ec <mem_init+0xd9b>
f01024d3:	68 50 4e 10 f0       	push   $0xf0104e50
f01024d8:	68 41 46 10 f0       	push   $0xf0104641
f01024dd:	68 54 03 00 00       	push   $0x354
f01024e2:	68 1b 46 10 f0       	push   $0xf010461b
f01024e7:	e8 9f db ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01024ec:	ba 00 10 00 00       	mov    $0x1000,%edx
f01024f1:	89 f8                	mov    %edi,%eax
f01024f3:	e8 0f eb ff ff       	call   f0101007 <check_va2pa>
f01024f8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024fb:	74 19                	je     f0102516 <mem_init+0xdc5>
f01024fd:	68 ac 4e 10 f0       	push   $0xf0104eac
f0102502:	68 41 46 10 f0       	push   $0xf0104641
f0102507:	68 55 03 00 00       	push   $0x355
f010250c:	68 1b 46 10 f0       	push   $0xf010461b
f0102511:	e8 75 db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102516:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010251b:	74 19                	je     f0102536 <mem_init+0xde5>
f010251d:	68 81 48 10 f0       	push   $0xf0104881
f0102522:	68 41 46 10 f0       	push   $0xf0104641
f0102527:	68 56 03 00 00       	push   $0x356
f010252c:	68 1b 46 10 f0       	push   $0xf010461b
f0102531:	e8 55 db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0102536:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010253b:	74 19                	je     f0102556 <mem_init+0xe05>
f010253d:	68 4f 48 10 f0       	push   $0xf010484f
f0102542:	68 41 46 10 f0       	push   $0xf0104641
f0102547:	68 57 03 00 00       	push   $0x357
f010254c:	68 1b 46 10 f0       	push   $0xf010461b
f0102551:	e8 35 db ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102556:	83 ec 0c             	sub    $0xc,%esp
f0102559:	6a 00                	push   $0x0
f010255b:	e8 d6 ee ff ff       	call   f0101436 <page_alloc>
f0102560:	83 c4 10             	add    $0x10,%esp
f0102563:	39 c3                	cmp    %eax,%ebx
f0102565:	75 04                	jne    f010256b <mem_init+0xe1a>
f0102567:	85 c0                	test   %eax,%eax
f0102569:	75 19                	jne    f0102584 <mem_init+0xe33>
f010256b:	68 d4 4e 10 f0       	push   $0xf0104ed4
f0102570:	68 41 46 10 f0       	push   $0xf0104641
f0102575:	68 5a 03 00 00       	push   $0x35a
f010257a:	68 1b 46 10 f0       	push   $0xf010461b
f010257f:	e8 07 db ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102584:	83 ec 0c             	sub    $0xc,%esp
f0102587:	6a 00                	push   $0x0
f0102589:	e8 a8 ee ff ff       	call   f0101436 <page_alloc>
f010258e:	83 c4 10             	add    $0x10,%esp
f0102591:	85 c0                	test   %eax,%eax
f0102593:	74 19                	je     f01025ae <mem_init+0xe5d>
f0102595:	68 a3 47 10 f0       	push   $0xf01047a3
f010259a:	68 41 46 10 f0       	push   $0xf0104641
f010259f:	68 5d 03 00 00       	push   $0x35d
f01025a4:	68 1b 46 10 f0       	push   $0xf010461b
f01025a9:	e8 dd da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01025ae:	8b 0d 6c 89 11 f0    	mov    0xf011896c,%ecx
f01025b4:	8b 11                	mov    (%ecx),%edx
f01025b6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01025bc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01025bf:	2b 05 70 89 11 f0    	sub    0xf0118970,%eax
f01025c5:	c1 f8 03             	sar    $0x3,%eax
f01025c8:	c1 e0 0c             	shl    $0xc,%eax
f01025cb:	39 c2                	cmp    %eax,%edx
f01025cd:	74 19                	je     f01025e8 <mem_init+0xe97>
f01025cf:	68 78 4b 10 f0       	push   $0xf0104b78
f01025d4:	68 41 46 10 f0       	push   $0xf0104641
f01025d9:	68 60 03 00 00       	push   $0x360
f01025de:	68 1b 46 10 f0       	push   $0xf010461b
f01025e3:	e8 a3 da ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01025e8:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01025ee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01025f1:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01025f6:	74 19                	je     f0102611 <mem_init+0xec0>
f01025f8:	68 06 48 10 f0       	push   $0xf0104806
f01025fd:	68 41 46 10 f0       	push   $0xf0104641
f0102602:	68 62 03 00 00       	push   $0x362
f0102607:	68 1b 46 10 f0       	push   $0xf010461b
f010260c:	e8 7a da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102611:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102614:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010261a:	83 ec 0c             	sub    $0xc,%esp
f010261d:	50                   	push   %eax
f010261e:	e8 88 ee ff ff       	call   f01014ab <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102623:	83 c4 0c             	add    $0xc,%esp
f0102626:	6a 01                	push   $0x1
f0102628:	68 00 10 40 00       	push   $0x401000
f010262d:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0102633:	e8 d5 ee ff ff       	call   f010150d <pgdir_walk>
f0102638:	89 c7                	mov    %eax,%edi
f010263a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010263d:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0102642:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102645:	8b 40 04             	mov    0x4(%eax),%eax
f0102648:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010264d:	8b 0d 68 89 11 f0    	mov    0xf0118968,%ecx
f0102653:	89 c2                	mov    %eax,%edx
f0102655:	c1 ea 0c             	shr    $0xc,%edx
f0102658:	83 c4 10             	add    $0x10,%esp
f010265b:	39 ca                	cmp    %ecx,%edx
f010265d:	72 15                	jb     f0102674 <mem_init+0xf23>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010265f:	50                   	push   %eax
f0102660:	68 c4 43 10 f0       	push   $0xf01043c4
f0102665:	68 69 03 00 00       	push   $0x369
f010266a:	68 1b 46 10 f0       	push   $0xf010461b
f010266f:	e8 17 da ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102674:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102679:	39 c7                	cmp    %eax,%edi
f010267b:	74 19                	je     f0102696 <mem_init+0xf45>
f010267d:	68 92 48 10 f0       	push   $0xf0104892
f0102682:	68 41 46 10 f0       	push   $0xf0104641
f0102687:	68 6a 03 00 00       	push   $0x36a
f010268c:	68 1b 46 10 f0       	push   $0xf010461b
f0102691:	e8 f5 d9 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102696:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102699:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01026a0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01026a3:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01026a9:	2b 05 70 89 11 f0    	sub    0xf0118970,%eax
f01026af:	c1 f8 03             	sar    $0x3,%eax
f01026b2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026b5:	89 c2                	mov    %eax,%edx
f01026b7:	c1 ea 0c             	shr    $0xc,%edx
f01026ba:	39 d1                	cmp    %edx,%ecx
f01026bc:	77 12                	ja     f01026d0 <mem_init+0xf7f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026be:	50                   	push   %eax
f01026bf:	68 c4 43 10 f0       	push   $0xf01043c4
f01026c4:	6a 52                	push   $0x52
f01026c6:	68 27 46 10 f0       	push   $0xf0104627
f01026cb:	e8 bb d9 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01026d0:	83 ec 04             	sub    $0x4,%esp
f01026d3:	68 00 10 00 00       	push   $0x1000
f01026d8:	68 ff 00 00 00       	push   $0xff
f01026dd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01026e2:	50                   	push   %eax
f01026e3:	e8 c9 11 00 00       	call   f01038b1 <memset>
	page_free(pp0);
f01026e8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01026eb:	89 3c 24             	mov    %edi,(%esp)
f01026ee:	e8 b8 ed ff ff       	call   f01014ab <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01026f3:	83 c4 0c             	add    $0xc,%esp
f01026f6:	6a 01                	push   $0x1
f01026f8:	6a 00                	push   $0x0
f01026fa:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0102700:	e8 08 ee ff ff       	call   f010150d <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102705:	89 fa                	mov    %edi,%edx
f0102707:	2b 15 70 89 11 f0    	sub    0xf0118970,%edx
f010270d:	c1 fa 03             	sar    $0x3,%edx
f0102710:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102713:	89 d0                	mov    %edx,%eax
f0102715:	c1 e8 0c             	shr    $0xc,%eax
f0102718:	83 c4 10             	add    $0x10,%esp
f010271b:	3b 05 68 89 11 f0    	cmp    0xf0118968,%eax
f0102721:	72 12                	jb     f0102735 <mem_init+0xfe4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102723:	52                   	push   %edx
f0102724:	68 c4 43 10 f0       	push   $0xf01043c4
f0102729:	6a 52                	push   $0x52
f010272b:	68 27 46 10 f0       	push   $0xf0104627
f0102730:	e8 56 d9 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0102735:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010273b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010273e:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102744:	f6 00 01             	testb  $0x1,(%eax)
f0102747:	74 19                	je     f0102762 <mem_init+0x1011>
f0102749:	68 aa 48 10 f0       	push   $0xf01048aa
f010274e:	68 41 46 10 f0       	push   $0xf0104641
f0102753:	68 74 03 00 00       	push   $0x374
f0102758:	68 1b 46 10 f0       	push   $0xf010461b
f010275d:	e8 29 d9 ff ff       	call   f010008b <_panic>
f0102762:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102765:	39 d0                	cmp    %edx,%eax
f0102767:	75 db                	jne    f0102744 <mem_init+0xff3>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102769:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f010276e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102774:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102777:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010277d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102780:	89 0d 3c 85 11 f0    	mov    %ecx,0xf011853c

	// free the pages we took
	page_free(pp0);
f0102786:	83 ec 0c             	sub    $0xc,%esp
f0102789:	50                   	push   %eax
f010278a:	e8 1c ed ff ff       	call   f01014ab <page_free>
	page_free(pp1);
f010278f:	89 1c 24             	mov    %ebx,(%esp)
f0102792:	e8 14 ed ff ff       	call   f01014ab <page_free>
	page_free(pp2);
f0102797:	89 34 24             	mov    %esi,(%esp)
f010279a:	e8 0c ed ff ff       	call   f01014ab <page_free>

	cprintf("check_page() succeeded!\n");
f010279f:	c7 04 24 c1 48 10 f0 	movl   $0xf01048c1,(%esp)
f01027a6:	e8 4b 06 00 00       	call   f0102df6 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U | PTE_P);
f01027ab:	a1 70 89 11 f0       	mov    0xf0118970,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027b0:	83 c4 10             	add    $0x10,%esp
f01027b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01027b8:	77 15                	ja     f01027cf <mem_init+0x107e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027ba:	50                   	push   %eax
f01027bb:	68 f4 49 10 f0       	push   $0xf01049f4
f01027c0:	68 ba 00 00 00       	push   $0xba
f01027c5:	68 1b 46 10 f0       	push   $0xf010461b
f01027ca:	e8 bc d8 ff ff       	call   f010008b <_panic>
f01027cf:	83 ec 08             	sub    $0x8,%esp
f01027d2:	6a 05                	push   $0x5
f01027d4:	05 00 00 00 10       	add    $0x10000000,%eax
f01027d9:	50                   	push   %eax
f01027da:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01027df:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01027e4:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f01027e9:	e8 b1 ed ff ff       	call   f010159f <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027ee:	83 c4 10             	add    $0x10,%esp
f01027f1:	b8 00 e0 10 f0       	mov    $0xf010e000,%eax
f01027f6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01027fb:	77 15                	ja     f0102812 <mem_init+0x10c1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027fd:	50                   	push   %eax
f01027fe:	68 f4 49 10 f0       	push   $0xf01049f4
f0102803:	68 c6 00 00 00       	push   $0xc6
f0102808:	68 1b 46 10 f0       	push   $0xf010461b
f010280d:	e8 79 d8 ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102812:	83 ec 08             	sub    $0x8,%esp
f0102815:	6a 02                	push   $0x2
f0102817:	68 00 e0 10 00       	push   $0x10e000
f010281c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102821:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102826:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f010282b:	e8 6f ed ff ff       	call   f010159f <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,0xffffffff-KERNBASE,0,PTE_W);
f0102830:	83 c4 08             	add    $0x8,%esp
f0102833:	6a 02                	push   $0x2
f0102835:	6a 00                	push   $0x0
f0102837:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010283c:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102841:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0102846:	e8 54 ed ff ff       	call   f010159f <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010284b:	8b 35 6c 89 11 f0    	mov    0xf011896c,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102851:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102856:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102859:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102860:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102865:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102868:	8b 3d 70 89 11 f0    	mov    0xf0118970,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010286e:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102871:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102874:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102879:	eb 55                	jmp    f01028d0 <mem_init+0x117f>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010287b:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102881:	89 f0                	mov    %esi,%eax
f0102883:	e8 7f e7 ff ff       	call   f0101007 <check_va2pa>
f0102888:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010288f:	77 15                	ja     f01028a6 <mem_init+0x1155>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102891:	57                   	push   %edi
f0102892:	68 f4 49 10 f0       	push   $0xf01049f4
f0102897:	68 b6 02 00 00       	push   $0x2b6
f010289c:	68 1b 46 10 f0       	push   $0xf010461b
f01028a1:	e8 e5 d7 ff ff       	call   f010008b <_panic>
f01028a6:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01028ad:	39 c2                	cmp    %eax,%edx
f01028af:	74 19                	je     f01028ca <mem_init+0x1179>
f01028b1:	68 f8 4e 10 f0       	push   $0xf0104ef8
f01028b6:	68 41 46 10 f0       	push   $0xf0104641
f01028bb:	68 b6 02 00 00       	push   $0x2b6
f01028c0:	68 1b 46 10 f0       	push   $0xf010461b
f01028c5:	e8 c1 d7 ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01028ca:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028d0:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01028d3:	77 a6                	ja     f010287b <mem_init+0x112a>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028d5:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01028d8:	c1 e7 0c             	shl    $0xc,%edi
f01028db:	bb 00 00 00 00       	mov    $0x0,%ebx
f01028e0:	eb 30                	jmp    f0102912 <mem_init+0x11c1>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01028e2:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01028e8:	89 f0                	mov    %esi,%eax
f01028ea:	e8 18 e7 ff ff       	call   f0101007 <check_va2pa>
f01028ef:	39 c3                	cmp    %eax,%ebx
f01028f1:	74 19                	je     f010290c <mem_init+0x11bb>
f01028f3:	68 2c 4f 10 f0       	push   $0xf0104f2c
f01028f8:	68 41 46 10 f0       	push   $0xf0104641
f01028fd:	68 bb 02 00 00       	push   $0x2bb
f0102902:	68 1b 46 10 f0       	push   $0xf010461b
f0102907:	e8 7f d7 ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010290c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102912:	39 fb                	cmp    %edi,%ebx
f0102914:	72 cc                	jb     f01028e2 <mem_init+0x1191>
f0102916:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010291b:	89 da                	mov    %ebx,%edx
f010291d:	89 f0                	mov    %esi,%eax
f010291f:	e8 e3 e6 ff ff       	call   f0101007 <check_va2pa>
f0102924:	8d 93 00 60 11 10    	lea    0x10116000(%ebx),%edx
f010292a:	39 c2                	cmp    %eax,%edx
f010292c:	74 19                	je     f0102947 <mem_init+0x11f6>
f010292e:	68 54 4f 10 f0       	push   $0xf0104f54
f0102933:	68 41 46 10 f0       	push   $0xf0104641
f0102938:	68 bf 02 00 00       	push   $0x2bf
f010293d:	68 1b 46 10 f0       	push   $0xf010461b
f0102942:	e8 44 d7 ff ff       	call   f010008b <_panic>
f0102947:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010294d:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102953:	75 c6                	jne    f010291b <mem_init+0x11ca>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102955:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010295a:	89 f0                	mov    %esi,%eax
f010295c:	e8 a6 e6 ff ff       	call   f0101007 <check_va2pa>
f0102961:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102964:	74 51                	je     f01029b7 <mem_init+0x1266>
f0102966:	68 9c 4f 10 f0       	push   $0xf0104f9c
f010296b:	68 41 46 10 f0       	push   $0xf0104641
f0102970:	68 c0 02 00 00       	push   $0x2c0
f0102975:	68 1b 46 10 f0       	push   $0xf010461b
f010297a:	e8 0c d7 ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010297f:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102984:	72 36                	jb     f01029bc <mem_init+0x126b>
f0102986:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010298b:	76 07                	jbe    f0102994 <mem_init+0x1243>
f010298d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102992:	75 28                	jne    f01029bc <mem_init+0x126b>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102994:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102998:	0f 85 83 00 00 00    	jne    f0102a21 <mem_init+0x12d0>
f010299e:	68 da 48 10 f0       	push   $0xf01048da
f01029a3:	68 41 46 10 f0       	push   $0xf0104641
f01029a8:	68 c8 02 00 00       	push   $0x2c8
f01029ad:	68 1b 46 10 f0       	push   $0xf010461b
f01029b2:	e8 d4 d6 ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01029b7:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01029bc:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01029c1:	76 3f                	jbe    f0102a02 <mem_init+0x12b1>
				assert(pgdir[i] & PTE_P);
f01029c3:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01029c6:	f6 c2 01             	test   $0x1,%dl
f01029c9:	75 19                	jne    f01029e4 <mem_init+0x1293>
f01029cb:	68 da 48 10 f0       	push   $0xf01048da
f01029d0:	68 41 46 10 f0       	push   $0xf0104641
f01029d5:	68 cc 02 00 00       	push   $0x2cc
f01029da:	68 1b 46 10 f0       	push   $0xf010461b
f01029df:	e8 a7 d6 ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f01029e4:	f6 c2 02             	test   $0x2,%dl
f01029e7:	75 38                	jne    f0102a21 <mem_init+0x12d0>
f01029e9:	68 eb 48 10 f0       	push   $0xf01048eb
f01029ee:	68 41 46 10 f0       	push   $0xf0104641
f01029f3:	68 cd 02 00 00       	push   $0x2cd
f01029f8:	68 1b 46 10 f0       	push   $0xf010461b
f01029fd:	e8 89 d6 ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102a02:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102a06:	74 19                	je     f0102a21 <mem_init+0x12d0>
f0102a08:	68 fc 48 10 f0       	push   $0xf01048fc
f0102a0d:	68 41 46 10 f0       	push   $0xf0104641
f0102a12:	68 cf 02 00 00       	push   $0x2cf
f0102a17:	68 1b 46 10 f0       	push   $0xf010461b
f0102a1c:	e8 6a d6 ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102a21:	83 c0 01             	add    $0x1,%eax
f0102a24:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102a29:	0f 86 50 ff ff ff    	jbe    f010297f <mem_init+0x122e>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a2f:	83 ec 0c             	sub    $0xc,%esp
f0102a32:	68 cc 4f 10 f0       	push   $0xf0104fcc
f0102a37:	e8 ba 03 00 00       	call   f0102df6 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102a3c:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a41:	83 c4 10             	add    $0x10,%esp
f0102a44:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a49:	77 15                	ja     f0102a60 <mem_init+0x130f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a4b:	50                   	push   %eax
f0102a4c:	68 f4 49 10 f0       	push   $0xf01049f4
f0102a51:	68 da 00 00 00       	push   $0xda
f0102a56:	68 1b 46 10 f0       	push   $0xf010461b
f0102a5b:	e8 2b d6 ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102a60:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a65:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102a68:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a6d:	e8 f9 e5 ff ff       	call   f010106b <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102a72:	0f 20 c0             	mov    %cr0,%eax
f0102a75:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102a78:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102a7d:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a80:	83 ec 0c             	sub    $0xc,%esp
f0102a83:	6a 00                	push   $0x0
f0102a85:	e8 ac e9 ff ff       	call   f0101436 <page_alloc>
f0102a8a:	89 c3                	mov    %eax,%ebx
f0102a8c:	83 c4 10             	add    $0x10,%esp
f0102a8f:	85 c0                	test   %eax,%eax
f0102a91:	75 19                	jne    f0102aac <mem_init+0x135b>
f0102a93:	68 f8 46 10 f0       	push   $0xf01046f8
f0102a98:	68 41 46 10 f0       	push   $0xf0104641
f0102a9d:	68 8f 03 00 00       	push   $0x38f
f0102aa2:	68 1b 46 10 f0       	push   $0xf010461b
f0102aa7:	e8 df d5 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0102aac:	83 ec 0c             	sub    $0xc,%esp
f0102aaf:	6a 00                	push   $0x0
f0102ab1:	e8 80 e9 ff ff       	call   f0101436 <page_alloc>
f0102ab6:	89 c7                	mov    %eax,%edi
f0102ab8:	83 c4 10             	add    $0x10,%esp
f0102abb:	85 c0                	test   %eax,%eax
f0102abd:	75 19                	jne    f0102ad8 <mem_init+0x1387>
f0102abf:	68 0e 47 10 f0       	push   $0xf010470e
f0102ac4:	68 41 46 10 f0       	push   $0xf0104641
f0102ac9:	68 90 03 00 00       	push   $0x390
f0102ace:	68 1b 46 10 f0       	push   $0xf010461b
f0102ad3:	e8 b3 d5 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102ad8:	83 ec 0c             	sub    $0xc,%esp
f0102adb:	6a 00                	push   $0x0
f0102add:	e8 54 e9 ff ff       	call   f0101436 <page_alloc>
f0102ae2:	89 c6                	mov    %eax,%esi
f0102ae4:	83 c4 10             	add    $0x10,%esp
f0102ae7:	85 c0                	test   %eax,%eax
f0102ae9:	75 19                	jne    f0102b04 <mem_init+0x13b3>
f0102aeb:	68 24 47 10 f0       	push   $0xf0104724
f0102af0:	68 41 46 10 f0       	push   $0xf0104641
f0102af5:	68 91 03 00 00       	push   $0x391
f0102afa:	68 1b 46 10 f0       	push   $0xf010461b
f0102aff:	e8 87 d5 ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102b04:	83 ec 0c             	sub    $0xc,%esp
f0102b07:	53                   	push   %ebx
f0102b08:	e8 9e e9 ff ff       	call   f01014ab <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b0d:	89 f8                	mov    %edi,%eax
f0102b0f:	2b 05 70 89 11 f0    	sub    0xf0118970,%eax
f0102b15:	c1 f8 03             	sar    $0x3,%eax
f0102b18:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b1b:	89 c2                	mov    %eax,%edx
f0102b1d:	c1 ea 0c             	shr    $0xc,%edx
f0102b20:	83 c4 10             	add    $0x10,%esp
f0102b23:	3b 15 68 89 11 f0    	cmp    0xf0118968,%edx
f0102b29:	72 12                	jb     f0102b3d <mem_init+0x13ec>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b2b:	50                   	push   %eax
f0102b2c:	68 c4 43 10 f0       	push   $0xf01043c4
f0102b31:	6a 52                	push   $0x52
f0102b33:	68 27 46 10 f0       	push   $0xf0104627
f0102b38:	e8 4e d5 ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b3d:	83 ec 04             	sub    $0x4,%esp
f0102b40:	68 00 10 00 00       	push   $0x1000
f0102b45:	6a 01                	push   $0x1
f0102b47:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b4c:	50                   	push   %eax
f0102b4d:	e8 5f 0d 00 00       	call   f01038b1 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b52:	89 f0                	mov    %esi,%eax
f0102b54:	2b 05 70 89 11 f0    	sub    0xf0118970,%eax
f0102b5a:	c1 f8 03             	sar    $0x3,%eax
f0102b5d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b60:	89 c2                	mov    %eax,%edx
f0102b62:	c1 ea 0c             	shr    $0xc,%edx
f0102b65:	83 c4 10             	add    $0x10,%esp
f0102b68:	3b 15 68 89 11 f0    	cmp    0xf0118968,%edx
f0102b6e:	72 12                	jb     f0102b82 <mem_init+0x1431>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b70:	50                   	push   %eax
f0102b71:	68 c4 43 10 f0       	push   $0xf01043c4
f0102b76:	6a 52                	push   $0x52
f0102b78:	68 27 46 10 f0       	push   $0xf0104627
f0102b7d:	e8 09 d5 ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b82:	83 ec 04             	sub    $0x4,%esp
f0102b85:	68 00 10 00 00       	push   $0x1000
f0102b8a:	6a 02                	push   $0x2
f0102b8c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b91:	50                   	push   %eax
f0102b92:	e8 1a 0d 00 00       	call   f01038b1 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b97:	6a 02                	push   $0x2
f0102b99:	68 00 10 00 00       	push   $0x1000
f0102b9e:	57                   	push   %edi
f0102b9f:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0102ba5:	e8 0d eb ff ff       	call   f01016b7 <page_insert>
	assert(pp1->pp_ref == 1);
f0102baa:	83 c4 20             	add    $0x20,%esp
f0102bad:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102bb2:	74 19                	je     f0102bcd <mem_init+0x147c>
f0102bb4:	68 f5 47 10 f0       	push   $0xf01047f5
f0102bb9:	68 41 46 10 f0       	push   $0xf0104641
f0102bbe:	68 96 03 00 00       	push   $0x396
f0102bc3:	68 1b 46 10 f0       	push   $0xf010461b
f0102bc8:	e8 be d4 ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102bcd:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102bd4:	01 01 01 
f0102bd7:	74 19                	je     f0102bf2 <mem_init+0x14a1>
f0102bd9:	68 ec 4f 10 f0       	push   $0xf0104fec
f0102bde:	68 41 46 10 f0       	push   $0xf0104641
f0102be3:	68 97 03 00 00       	push   $0x397
f0102be8:	68 1b 46 10 f0       	push   $0xf010461b
f0102bed:	e8 99 d4 ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102bf2:	6a 02                	push   $0x2
f0102bf4:	68 00 10 00 00       	push   $0x1000
f0102bf9:	56                   	push   %esi
f0102bfa:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0102c00:	e8 b2 ea ff ff       	call   f01016b7 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c05:	83 c4 10             	add    $0x10,%esp
f0102c08:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c0f:	02 02 02 
f0102c12:	74 19                	je     f0102c2d <mem_init+0x14dc>
f0102c14:	68 10 50 10 f0       	push   $0xf0105010
f0102c19:	68 41 46 10 f0       	push   $0xf0104641
f0102c1e:	68 99 03 00 00       	push   $0x399
f0102c23:	68 1b 46 10 f0       	push   $0xf010461b
f0102c28:	e8 5e d4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102c2d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c32:	74 19                	je     f0102c4d <mem_init+0x14fc>
f0102c34:	68 17 48 10 f0       	push   $0xf0104817
f0102c39:	68 41 46 10 f0       	push   $0xf0104641
f0102c3e:	68 9a 03 00 00       	push   $0x39a
f0102c43:	68 1b 46 10 f0       	push   $0xf010461b
f0102c48:	e8 3e d4 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102c4d:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102c52:	74 19                	je     f0102c6d <mem_init+0x151c>
f0102c54:	68 81 48 10 f0       	push   $0xf0104881
f0102c59:	68 41 46 10 f0       	push   $0xf0104641
f0102c5e:	68 9b 03 00 00       	push   $0x39b
f0102c63:	68 1b 46 10 f0       	push   $0xf010461b
f0102c68:	e8 1e d4 ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c6d:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c74:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c77:	89 f0                	mov    %esi,%eax
f0102c79:	2b 05 70 89 11 f0    	sub    0xf0118970,%eax
f0102c7f:	c1 f8 03             	sar    $0x3,%eax
f0102c82:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c85:	89 c2                	mov    %eax,%edx
f0102c87:	c1 ea 0c             	shr    $0xc,%edx
f0102c8a:	3b 15 68 89 11 f0    	cmp    0xf0118968,%edx
f0102c90:	72 12                	jb     f0102ca4 <mem_init+0x1553>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c92:	50                   	push   %eax
f0102c93:	68 c4 43 10 f0       	push   $0xf01043c4
f0102c98:	6a 52                	push   $0x52
f0102c9a:	68 27 46 10 f0       	push   $0xf0104627
f0102c9f:	e8 e7 d3 ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ca4:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102cab:	03 03 03 
f0102cae:	74 19                	je     f0102cc9 <mem_init+0x1578>
f0102cb0:	68 34 50 10 f0       	push   $0xf0105034
f0102cb5:	68 41 46 10 f0       	push   $0xf0104641
f0102cba:	68 9d 03 00 00       	push   $0x39d
f0102cbf:	68 1b 46 10 f0       	push   $0xf010461b
f0102cc4:	e8 c2 d3 ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102cc9:	83 ec 08             	sub    $0x8,%esp
f0102ccc:	68 00 10 00 00       	push   $0x1000
f0102cd1:	ff 35 6c 89 11 f0    	pushl  0xf011896c
f0102cd7:	e8 95 e9 ff ff       	call   f0101671 <page_remove>
	assert(pp2->pp_ref == 0);
f0102cdc:	83 c4 10             	add    $0x10,%esp
f0102cdf:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102ce4:	74 19                	je     f0102cff <mem_init+0x15ae>
f0102ce6:	68 4f 48 10 f0       	push   $0xf010484f
f0102ceb:	68 41 46 10 f0       	push   $0xf0104641
f0102cf0:	68 9f 03 00 00       	push   $0x39f
f0102cf5:	68 1b 46 10 f0       	push   $0xf010461b
f0102cfa:	e8 8c d3 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102cff:	8b 0d 6c 89 11 f0    	mov    0xf011896c,%ecx
f0102d05:	8b 11                	mov    (%ecx),%edx
f0102d07:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102d0d:	89 d8                	mov    %ebx,%eax
f0102d0f:	2b 05 70 89 11 f0    	sub    0xf0118970,%eax
f0102d15:	c1 f8 03             	sar    $0x3,%eax
f0102d18:	c1 e0 0c             	shl    $0xc,%eax
f0102d1b:	39 c2                	cmp    %eax,%edx
f0102d1d:	74 19                	je     f0102d38 <mem_init+0x15e7>
f0102d1f:	68 78 4b 10 f0       	push   $0xf0104b78
f0102d24:	68 41 46 10 f0       	push   $0xf0104641
f0102d29:	68 a2 03 00 00       	push   $0x3a2
f0102d2e:	68 1b 46 10 f0       	push   $0xf010461b
f0102d33:	e8 53 d3 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102d38:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102d3e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d43:	74 19                	je     f0102d5e <mem_init+0x160d>
f0102d45:	68 06 48 10 f0       	push   $0xf0104806
f0102d4a:	68 41 46 10 f0       	push   $0xf0104641
f0102d4f:	68 a4 03 00 00       	push   $0x3a4
f0102d54:	68 1b 46 10 f0       	push   $0xf010461b
f0102d59:	e8 2d d3 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102d5e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102d64:	83 ec 0c             	sub    $0xc,%esp
f0102d67:	53                   	push   %ebx
f0102d68:	e8 3e e7 ff ff       	call   f01014ab <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d6d:	c7 04 24 60 50 10 f0 	movl   $0xf0105060,(%esp)
f0102d74:	e8 7d 00 00 00       	call   f0102df6 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102d79:	83 c4 10             	add    $0x10,%esp
f0102d7c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d7f:	5b                   	pop    %ebx
f0102d80:	5e                   	pop    %esi
f0102d81:	5f                   	pop    %edi
f0102d82:	5d                   	pop    %ebp
f0102d83:	c3                   	ret    

f0102d84 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102d84:	55                   	push   %ebp
f0102d85:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102d87:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d8a:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102d8d:	5d                   	pop    %ebp
f0102d8e:	c3                   	ret    

f0102d8f <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102d8f:	55                   	push   %ebp
f0102d90:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d92:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d97:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d9a:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102d9b:	ba 71 00 00 00       	mov    $0x71,%edx
f0102da0:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102da1:	0f b6 c0             	movzbl %al,%eax
}
f0102da4:	5d                   	pop    %ebp
f0102da5:	c3                   	ret    

f0102da6 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102da6:	55                   	push   %ebp
f0102da7:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102da9:	ba 70 00 00 00       	mov    $0x70,%edx
f0102dae:	8b 45 08             	mov    0x8(%ebp),%eax
f0102db1:	ee                   	out    %al,(%dx)
f0102db2:	ba 71 00 00 00       	mov    $0x71,%edx
f0102db7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102dba:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102dbb:	5d                   	pop    %ebp
f0102dbc:	c3                   	ret    

f0102dbd <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102dbd:	55                   	push   %ebp
f0102dbe:	89 e5                	mov    %esp,%ebp
f0102dc0:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102dc3:	ff 75 08             	pushl  0x8(%ebp)
f0102dc6:	e8 35 d8 ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f0102dcb:	83 c4 10             	add    $0x10,%esp
f0102dce:	c9                   	leave  
f0102dcf:	c3                   	ret    

f0102dd0 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102dd0:	55                   	push   %ebp
f0102dd1:	89 e5                	mov    %esp,%ebp
f0102dd3:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102dd6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102ddd:	ff 75 0c             	pushl  0xc(%ebp)
f0102de0:	ff 75 08             	pushl  0x8(%ebp)
f0102de3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102de6:	50                   	push   %eax
f0102de7:	68 bd 2d 10 f0       	push   $0xf0102dbd
f0102dec:	e8 54 04 00 00       	call   f0103245 <vprintfmt>
	return cnt;
}
f0102df1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102df4:	c9                   	leave  
f0102df5:	c3                   	ret    

f0102df6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102df6:	55                   	push   %ebp
f0102df7:	89 e5                	mov    %esp,%ebp
f0102df9:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102dfc:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102dff:	50                   	push   %eax
f0102e00:	ff 75 08             	pushl  0x8(%ebp)
f0102e03:	e8 c8 ff ff ff       	call   f0102dd0 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102e08:	c9                   	leave  
f0102e09:	c3                   	ret    

f0102e0a <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102e0a:	55                   	push   %ebp
f0102e0b:	89 e5                	mov    %esp,%ebp
f0102e0d:	57                   	push   %edi
f0102e0e:	56                   	push   %esi
f0102e0f:	53                   	push   %ebx
f0102e10:	83 ec 14             	sub    $0x14,%esp
f0102e13:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102e16:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102e19:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102e1c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102e1f:	8b 1a                	mov    (%edx),%ebx
f0102e21:	8b 01                	mov    (%ecx),%eax
f0102e23:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102e26:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102e2d:	eb 7f                	jmp    f0102eae <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102e2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102e32:	01 d8                	add    %ebx,%eax
f0102e34:	89 c6                	mov    %eax,%esi
f0102e36:	c1 ee 1f             	shr    $0x1f,%esi
f0102e39:	01 c6                	add    %eax,%esi
f0102e3b:	d1 fe                	sar    %esi
f0102e3d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102e40:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102e43:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102e46:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e48:	eb 03                	jmp    f0102e4d <stab_binsearch+0x43>
			m--;
f0102e4a:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e4d:	39 c3                	cmp    %eax,%ebx
f0102e4f:	7f 0d                	jg     f0102e5e <stab_binsearch+0x54>
f0102e51:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102e55:	83 ea 0c             	sub    $0xc,%edx
f0102e58:	39 f9                	cmp    %edi,%ecx
f0102e5a:	75 ee                	jne    f0102e4a <stab_binsearch+0x40>
f0102e5c:	eb 05                	jmp    f0102e63 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102e5e:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102e61:	eb 4b                	jmp    f0102eae <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102e63:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102e66:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102e69:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102e6d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102e70:	76 11                	jbe    f0102e83 <stab_binsearch+0x79>
			*region_left = m;
f0102e72:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102e75:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102e77:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e7a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102e81:	eb 2b                	jmp    f0102eae <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102e83:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102e86:	73 14                	jae    f0102e9c <stab_binsearch+0x92>
			*region_right = m - 1;
f0102e88:	83 e8 01             	sub    $0x1,%eax
f0102e8b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102e8e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102e91:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e93:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102e9a:	eb 12                	jmp    f0102eae <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102e9c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102e9f:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102ea1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102ea5:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102ea7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102eae:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102eb1:	0f 8e 78 ff ff ff    	jle    f0102e2f <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102eb7:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102ebb:	75 0f                	jne    f0102ecc <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102ebd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ec0:	8b 00                	mov    (%eax),%eax
f0102ec2:	83 e8 01             	sub    $0x1,%eax
f0102ec5:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102ec8:	89 06                	mov    %eax,(%esi)
f0102eca:	eb 2c                	jmp    f0102ef8 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ecc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ecf:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102ed1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102ed4:	8b 0e                	mov    (%esi),%ecx
f0102ed6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102ed9:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102edc:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102edf:	eb 03                	jmp    f0102ee4 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102ee1:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ee4:	39 c8                	cmp    %ecx,%eax
f0102ee6:	7e 0b                	jle    f0102ef3 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102ee8:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102eec:	83 ea 0c             	sub    $0xc,%edx
f0102eef:	39 df                	cmp    %ebx,%edi
f0102ef1:	75 ee                	jne    f0102ee1 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102ef3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102ef6:	89 06                	mov    %eax,(%esi)
	}
}
f0102ef8:	83 c4 14             	add    $0x14,%esp
f0102efb:	5b                   	pop    %ebx
f0102efc:	5e                   	pop    %esi
f0102efd:	5f                   	pop    %edi
f0102efe:	5d                   	pop    %ebp
f0102eff:	c3                   	ret    

f0102f00 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102f00:	55                   	push   %ebp
f0102f01:	89 e5                	mov    %esp,%ebp
f0102f03:	57                   	push   %edi
f0102f04:	56                   	push   %esi
f0102f05:	53                   	push   %ebx
f0102f06:	83 ec 3c             	sub    $0x3c,%esp
f0102f09:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f0c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102f0f:	c7 03 8c 50 10 f0    	movl   $0xf010508c,(%ebx)
	info->eip_line = 0;
f0102f15:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102f1c:	c7 43 08 8c 50 10 f0 	movl   $0xf010508c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102f23:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102f2a:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102f2d:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102f34:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102f3a:	76 11                	jbe    f0102f4d <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f3c:	b8 25 d7 10 f0       	mov    $0xf010d725,%eax
f0102f41:	3d f5 b7 10 f0       	cmp    $0xf010b7f5,%eax
f0102f46:	77 19                	ja     f0102f61 <debuginfo_eip+0x61>
f0102f48:	e9 ac 01 00 00       	jmp    f01030f9 <debuginfo_eip+0x1f9>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102f4d:	83 ec 04             	sub    $0x4,%esp
f0102f50:	68 96 50 10 f0       	push   $0xf0105096
f0102f55:	6a 7f                	push   $0x7f
f0102f57:	68 a3 50 10 f0       	push   $0xf01050a3
f0102f5c:	e8 2a d1 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f61:	80 3d 24 d7 10 f0 00 	cmpb   $0x0,0xf010d724
f0102f68:	0f 85 92 01 00 00    	jne    f0103100 <debuginfo_eip+0x200>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102f6e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102f75:	b8 f4 b7 10 f0       	mov    $0xf010b7f4,%eax
f0102f7a:	2d c0 52 10 f0       	sub    $0xf01052c0,%eax
f0102f7f:	c1 f8 02             	sar    $0x2,%eax
f0102f82:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102f88:	83 e8 01             	sub    $0x1,%eax
f0102f8b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102f8e:	83 ec 08             	sub    $0x8,%esp
f0102f91:	56                   	push   %esi
f0102f92:	6a 64                	push   $0x64
f0102f94:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102f97:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102f9a:	b8 c0 52 10 f0       	mov    $0xf01052c0,%eax
f0102f9f:	e8 66 fe ff ff       	call   f0102e0a <stab_binsearch>
	if (lfile == 0)
f0102fa4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fa7:	83 c4 10             	add    $0x10,%esp
f0102faa:	85 c0                	test   %eax,%eax
f0102fac:	0f 84 55 01 00 00    	je     f0103107 <debuginfo_eip+0x207>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102fb2:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102fb5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102fb8:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102fbb:	83 ec 08             	sub    $0x8,%esp
f0102fbe:	56                   	push   %esi
f0102fbf:	6a 24                	push   $0x24
f0102fc1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102fc4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102fc7:	b8 c0 52 10 f0       	mov    $0xf01052c0,%eax
f0102fcc:	e8 39 fe ff ff       	call   f0102e0a <stab_binsearch>

	if (lfun <= rfun) {
f0102fd1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102fd4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102fd7:	83 c4 10             	add    $0x10,%esp
f0102fda:	39 d0                	cmp    %edx,%eax
f0102fdc:	7f 40                	jg     f010301e <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102fde:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102fe1:	c1 e1 02             	shl    $0x2,%ecx
f0102fe4:	8d b9 c0 52 10 f0    	lea    -0xfefad40(%ecx),%edi
f0102fea:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102fed:	8b b9 c0 52 10 f0    	mov    -0xfefad40(%ecx),%edi
f0102ff3:	b9 25 d7 10 f0       	mov    $0xf010d725,%ecx
f0102ff8:	81 e9 f5 b7 10 f0    	sub    $0xf010b7f5,%ecx
f0102ffe:	39 cf                	cmp    %ecx,%edi
f0103000:	73 09                	jae    f010300b <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103002:	81 c7 f5 b7 10 f0    	add    $0xf010b7f5,%edi
f0103008:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010300b:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010300e:	8b 4f 08             	mov    0x8(%edi),%ecx
f0103011:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103014:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103016:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103019:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010301c:	eb 0f                	jmp    f010302d <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010301e:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103021:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103024:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103027:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010302a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010302d:	83 ec 08             	sub    $0x8,%esp
f0103030:	6a 3a                	push   $0x3a
f0103032:	ff 73 08             	pushl  0x8(%ebx)
f0103035:	e8 5b 08 00 00       	call   f0103895 <strfind>
f010303a:	2b 43 08             	sub    0x8(%ebx),%eax
f010303d:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	//(N_SLINE)
	stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
f0103040:	83 c4 08             	add    $0x8,%esp
f0103043:	56                   	push   %esi
f0103044:	6a 44                	push   $0x44
f0103046:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103049:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010304c:	b8 c0 52 10 f0       	mov    $0xf01052c0,%eax
f0103051:	e8 b4 fd ff ff       	call   f0102e0a <stab_binsearch>
	if (lline>rline) return -1;
f0103056:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103059:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010305c:	83 c4 10             	add    $0x10,%esp
f010305f:	39 d0                	cmp    %edx,%eax
f0103061:	0f 8f a7 00 00 00    	jg     f010310e <debuginfo_eip+0x20e>
	info->eip_line = rline-lfile;
f0103067:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010306a:	29 fa                	sub    %edi,%edx
f010306c:	89 53 04             	mov    %edx,0x4(%ebx)
f010306f:	89 c2                	mov    %eax,%edx
f0103071:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103074:	8d 04 85 c0 52 10 f0 	lea    -0xfefad40(,%eax,4),%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010307b:	eb 06                	jmp    f0103083 <debuginfo_eip+0x183>
f010307d:	83 ea 01             	sub    $0x1,%edx
f0103080:	83 e8 0c             	sub    $0xc,%eax
f0103083:	39 d7                	cmp    %edx,%edi
f0103085:	7f 34                	jg     f01030bb <debuginfo_eip+0x1bb>
	       && stabs[lline].n_type != N_SOL
f0103087:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f010308b:	80 f9 84             	cmp    $0x84,%cl
f010308e:	74 0b                	je     f010309b <debuginfo_eip+0x19b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103090:	80 f9 64             	cmp    $0x64,%cl
f0103093:	75 e8                	jne    f010307d <debuginfo_eip+0x17d>
f0103095:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0103099:	74 e2                	je     f010307d <debuginfo_eip+0x17d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010309b:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010309e:	8b 14 85 c0 52 10 f0 	mov    -0xfefad40(,%eax,4),%edx
f01030a5:	b8 25 d7 10 f0       	mov    $0xf010d725,%eax
f01030aa:	2d f5 b7 10 f0       	sub    $0xf010b7f5,%eax
f01030af:	39 c2                	cmp    %eax,%edx
f01030b1:	73 08                	jae    f01030bb <debuginfo_eip+0x1bb>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01030b3:	81 c2 f5 b7 10 f0    	add    $0xf010b7f5,%edx
f01030b9:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01030bb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01030be:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01030c1:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01030c6:	39 f2                	cmp    %esi,%edx
f01030c8:	7d 50                	jge    f010311a <debuginfo_eip+0x21a>
		for (lline = lfun + 1;
f01030ca:	83 c2 01             	add    $0x1,%edx
f01030cd:	89 d0                	mov    %edx,%eax
f01030cf:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01030d2:	8d 14 95 c0 52 10 f0 	lea    -0xfefad40(,%edx,4),%edx
f01030d9:	eb 04                	jmp    f01030df <debuginfo_eip+0x1df>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01030db:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01030df:	39 c6                	cmp    %eax,%esi
f01030e1:	7e 32                	jle    f0103115 <debuginfo_eip+0x215>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01030e3:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01030e7:	83 c0 01             	add    $0x1,%eax
f01030ea:	83 c2 0c             	add    $0xc,%edx
f01030ed:	80 f9 a0             	cmp    $0xa0,%cl
f01030f0:	74 e9                	je     f01030db <debuginfo_eip+0x1db>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01030f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01030f7:	eb 21                	jmp    f010311a <debuginfo_eip+0x21a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01030f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01030fe:	eb 1a                	jmp    f010311a <debuginfo_eip+0x21a>
f0103100:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103105:	eb 13                	jmp    f010311a <debuginfo_eip+0x21a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103107:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010310c:	eb 0c                	jmp    f010311a <debuginfo_eip+0x21a>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	//(N_SLINE)
	stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
	if (lline>rline) return -1;
f010310e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103113:	eb 05                	jmp    f010311a <debuginfo_eip+0x21a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103115:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010311a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010311d:	5b                   	pop    %ebx
f010311e:	5e                   	pop    %esi
f010311f:	5f                   	pop    %edi
f0103120:	5d                   	pop    %ebp
f0103121:	c3                   	ret    

f0103122 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103122:	55                   	push   %ebp
f0103123:	89 e5                	mov    %esp,%ebp
f0103125:	57                   	push   %edi
f0103126:	56                   	push   %esi
f0103127:	53                   	push   %ebx
f0103128:	83 ec 1c             	sub    $0x1c,%esp
f010312b:	89 c7                	mov    %eax,%edi
f010312d:	89 d6                	mov    %edx,%esi
f010312f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103132:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103135:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103138:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010313b:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010313e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103143:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103146:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103149:	39 d3                	cmp    %edx,%ebx
f010314b:	72 05                	jb     f0103152 <printnum+0x30>
f010314d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103150:	77 45                	ja     f0103197 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103152:	83 ec 0c             	sub    $0xc,%esp
f0103155:	ff 75 18             	pushl  0x18(%ebp)
f0103158:	8b 45 14             	mov    0x14(%ebp),%eax
f010315b:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010315e:	53                   	push   %ebx
f010315f:	ff 75 10             	pushl  0x10(%ebp)
f0103162:	83 ec 08             	sub    $0x8,%esp
f0103165:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103168:	ff 75 e0             	pushl  -0x20(%ebp)
f010316b:	ff 75 dc             	pushl  -0x24(%ebp)
f010316e:	ff 75 d8             	pushl  -0x28(%ebp)
f0103171:	e8 4a 09 00 00       	call   f0103ac0 <__udivdi3>
f0103176:	83 c4 18             	add    $0x18,%esp
f0103179:	52                   	push   %edx
f010317a:	50                   	push   %eax
f010317b:	89 f2                	mov    %esi,%edx
f010317d:	89 f8                	mov    %edi,%eax
f010317f:	e8 9e ff ff ff       	call   f0103122 <printnum>
f0103184:	83 c4 20             	add    $0x20,%esp
f0103187:	eb 18                	jmp    f01031a1 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103189:	83 ec 08             	sub    $0x8,%esp
f010318c:	56                   	push   %esi
f010318d:	ff 75 18             	pushl  0x18(%ebp)
f0103190:	ff d7                	call   *%edi
f0103192:	83 c4 10             	add    $0x10,%esp
f0103195:	eb 03                	jmp    f010319a <printnum+0x78>
f0103197:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010319a:	83 eb 01             	sub    $0x1,%ebx
f010319d:	85 db                	test   %ebx,%ebx
f010319f:	7f e8                	jg     f0103189 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01031a1:	83 ec 08             	sub    $0x8,%esp
f01031a4:	56                   	push   %esi
f01031a5:	83 ec 04             	sub    $0x4,%esp
f01031a8:	ff 75 e4             	pushl  -0x1c(%ebp)
f01031ab:	ff 75 e0             	pushl  -0x20(%ebp)
f01031ae:	ff 75 dc             	pushl  -0x24(%ebp)
f01031b1:	ff 75 d8             	pushl  -0x28(%ebp)
f01031b4:	e8 37 0a 00 00       	call   f0103bf0 <__umoddi3>
f01031b9:	83 c4 14             	add    $0x14,%esp
f01031bc:	0f be 80 b1 50 10 f0 	movsbl -0xfefaf4f(%eax),%eax
f01031c3:	50                   	push   %eax
f01031c4:	ff d7                	call   *%edi
}
f01031c6:	83 c4 10             	add    $0x10,%esp
f01031c9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031cc:	5b                   	pop    %ebx
f01031cd:	5e                   	pop    %esi
f01031ce:	5f                   	pop    %edi
f01031cf:	5d                   	pop    %ebp
f01031d0:	c3                   	ret    

f01031d1 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01031d1:	55                   	push   %ebp
f01031d2:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01031d4:	83 fa 01             	cmp    $0x1,%edx
f01031d7:	7e 0e                	jle    f01031e7 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01031d9:	8b 10                	mov    (%eax),%edx
f01031db:	8d 4a 08             	lea    0x8(%edx),%ecx
f01031de:	89 08                	mov    %ecx,(%eax)
f01031e0:	8b 02                	mov    (%edx),%eax
f01031e2:	8b 52 04             	mov    0x4(%edx),%edx
f01031e5:	eb 22                	jmp    f0103209 <getuint+0x38>
	else if (lflag)
f01031e7:	85 d2                	test   %edx,%edx
f01031e9:	74 10                	je     f01031fb <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01031eb:	8b 10                	mov    (%eax),%edx
f01031ed:	8d 4a 04             	lea    0x4(%edx),%ecx
f01031f0:	89 08                	mov    %ecx,(%eax)
f01031f2:	8b 02                	mov    (%edx),%eax
f01031f4:	ba 00 00 00 00       	mov    $0x0,%edx
f01031f9:	eb 0e                	jmp    f0103209 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01031fb:	8b 10                	mov    (%eax),%edx
f01031fd:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103200:	89 08                	mov    %ecx,(%eax)
f0103202:	8b 02                	mov    (%edx),%eax
f0103204:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103209:	5d                   	pop    %ebp
f010320a:	c3                   	ret    

f010320b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010320b:	55                   	push   %ebp
f010320c:	89 e5                	mov    %esp,%ebp
f010320e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103211:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103215:	8b 10                	mov    (%eax),%edx
f0103217:	3b 50 04             	cmp    0x4(%eax),%edx
f010321a:	73 0a                	jae    f0103226 <sprintputch+0x1b>
		*b->buf++ = ch;
f010321c:	8d 4a 01             	lea    0x1(%edx),%ecx
f010321f:	89 08                	mov    %ecx,(%eax)
f0103221:	8b 45 08             	mov    0x8(%ebp),%eax
f0103224:	88 02                	mov    %al,(%edx)
}
f0103226:	5d                   	pop    %ebp
f0103227:	c3                   	ret    

f0103228 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103228:	55                   	push   %ebp
f0103229:	89 e5                	mov    %esp,%ebp
f010322b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010322e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103231:	50                   	push   %eax
f0103232:	ff 75 10             	pushl  0x10(%ebp)
f0103235:	ff 75 0c             	pushl  0xc(%ebp)
f0103238:	ff 75 08             	pushl  0x8(%ebp)
f010323b:	e8 05 00 00 00       	call   f0103245 <vprintfmt>
	va_end(ap);
}
f0103240:	83 c4 10             	add    $0x10,%esp
f0103243:	c9                   	leave  
f0103244:	c3                   	ret    

f0103245 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103245:	55                   	push   %ebp
f0103246:	89 e5                	mov    %esp,%ebp
f0103248:	57                   	push   %edi
f0103249:	56                   	push   %esi
f010324a:	53                   	push   %ebx
f010324b:	83 ec 2c             	sub    $0x2c,%esp
f010324e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103251:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103254:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103257:	eb 12                	jmp    f010326b <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103259:	85 c0                	test   %eax,%eax
f010325b:	0f 84 89 03 00 00    	je     f01035ea <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0103261:	83 ec 08             	sub    $0x8,%esp
f0103264:	53                   	push   %ebx
f0103265:	50                   	push   %eax
f0103266:	ff d6                	call   *%esi
f0103268:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010326b:	83 c7 01             	add    $0x1,%edi
f010326e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103272:	83 f8 25             	cmp    $0x25,%eax
f0103275:	75 e2                	jne    f0103259 <vprintfmt+0x14>
f0103277:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f010327b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103282:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103289:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103290:	ba 00 00 00 00       	mov    $0x0,%edx
f0103295:	eb 07                	jmp    f010329e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103297:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f010329a:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010329e:	8d 47 01             	lea    0x1(%edi),%eax
f01032a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01032a4:	0f b6 07             	movzbl (%edi),%eax
f01032a7:	0f b6 c8             	movzbl %al,%ecx
f01032aa:	83 e8 23             	sub    $0x23,%eax
f01032ad:	3c 55                	cmp    $0x55,%al
f01032af:	0f 87 1a 03 00 00    	ja     f01035cf <vprintfmt+0x38a>
f01032b5:	0f b6 c0             	movzbl %al,%eax
f01032b8:	ff 24 85 3c 51 10 f0 	jmp    *-0xfefaec4(,%eax,4)
f01032bf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01032c2:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01032c6:	eb d6                	jmp    f010329e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01032cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01032d0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01032d3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01032d6:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f01032da:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f01032dd:	8d 51 d0             	lea    -0x30(%ecx),%edx
f01032e0:	83 fa 09             	cmp    $0x9,%edx
f01032e3:	77 39                	ja     f010331e <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01032e5:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01032e8:	eb e9                	jmp    f01032d3 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01032ea:	8b 45 14             	mov    0x14(%ebp),%eax
f01032ed:	8d 48 04             	lea    0x4(%eax),%ecx
f01032f0:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01032f3:	8b 00                	mov    (%eax),%eax
f01032f5:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01032fb:	eb 27                	jmp    f0103324 <vprintfmt+0xdf>
f01032fd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103300:	85 c0                	test   %eax,%eax
f0103302:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103307:	0f 49 c8             	cmovns %eax,%ecx
f010330a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010330d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103310:	eb 8c                	jmp    f010329e <vprintfmt+0x59>
f0103312:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103315:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010331c:	eb 80                	jmp    f010329e <vprintfmt+0x59>
f010331e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103321:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103324:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103328:	0f 89 70 ff ff ff    	jns    f010329e <vprintfmt+0x59>
				width = precision, precision = -1;
f010332e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103331:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103334:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010333b:	e9 5e ff ff ff       	jmp    f010329e <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103340:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103343:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103346:	e9 53 ff ff ff       	jmp    f010329e <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010334b:	8b 45 14             	mov    0x14(%ebp),%eax
f010334e:	8d 50 04             	lea    0x4(%eax),%edx
f0103351:	89 55 14             	mov    %edx,0x14(%ebp)
f0103354:	83 ec 08             	sub    $0x8,%esp
f0103357:	53                   	push   %ebx
f0103358:	ff 30                	pushl  (%eax)
f010335a:	ff d6                	call   *%esi
			break;
f010335c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010335f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103362:	e9 04 ff ff ff       	jmp    f010326b <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103367:	8b 45 14             	mov    0x14(%ebp),%eax
f010336a:	8d 50 04             	lea    0x4(%eax),%edx
f010336d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103370:	8b 00                	mov    (%eax),%eax
f0103372:	99                   	cltd   
f0103373:	31 d0                	xor    %edx,%eax
f0103375:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103377:	83 f8 06             	cmp    $0x6,%eax
f010337a:	7f 0b                	jg     f0103387 <vprintfmt+0x142>
f010337c:	8b 14 85 94 52 10 f0 	mov    -0xfefad6c(,%eax,4),%edx
f0103383:	85 d2                	test   %edx,%edx
f0103385:	75 18                	jne    f010339f <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103387:	50                   	push   %eax
f0103388:	68 c9 50 10 f0       	push   $0xf01050c9
f010338d:	53                   	push   %ebx
f010338e:	56                   	push   %esi
f010338f:	e8 94 fe ff ff       	call   f0103228 <printfmt>
f0103394:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103397:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010339a:	e9 cc fe ff ff       	jmp    f010326b <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f010339f:	52                   	push   %edx
f01033a0:	68 53 46 10 f0       	push   $0xf0104653
f01033a5:	53                   	push   %ebx
f01033a6:	56                   	push   %esi
f01033a7:	e8 7c fe ff ff       	call   f0103228 <printfmt>
f01033ac:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01033b2:	e9 b4 fe ff ff       	jmp    f010326b <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01033b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01033ba:	8d 50 04             	lea    0x4(%eax),%edx
f01033bd:	89 55 14             	mov    %edx,0x14(%ebp)
f01033c0:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01033c2:	85 ff                	test   %edi,%edi
f01033c4:	b8 c2 50 10 f0       	mov    $0xf01050c2,%eax
f01033c9:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01033cc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01033d0:	0f 8e 94 00 00 00    	jle    f010346a <vprintfmt+0x225>
f01033d6:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01033da:	0f 84 98 00 00 00    	je     f0103478 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f01033e0:	83 ec 08             	sub    $0x8,%esp
f01033e3:	ff 75 d0             	pushl  -0x30(%ebp)
f01033e6:	57                   	push   %edi
f01033e7:	e8 5f 03 00 00       	call   f010374b <strnlen>
f01033ec:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01033ef:	29 c1                	sub    %eax,%ecx
f01033f1:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f01033f4:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01033f7:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01033fb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01033fe:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103401:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103403:	eb 0f                	jmp    f0103414 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103405:	83 ec 08             	sub    $0x8,%esp
f0103408:	53                   	push   %ebx
f0103409:	ff 75 e0             	pushl  -0x20(%ebp)
f010340c:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010340e:	83 ef 01             	sub    $0x1,%edi
f0103411:	83 c4 10             	add    $0x10,%esp
f0103414:	85 ff                	test   %edi,%edi
f0103416:	7f ed                	jg     f0103405 <vprintfmt+0x1c0>
f0103418:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010341b:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010341e:	85 c9                	test   %ecx,%ecx
f0103420:	b8 00 00 00 00       	mov    $0x0,%eax
f0103425:	0f 49 c1             	cmovns %ecx,%eax
f0103428:	29 c1                	sub    %eax,%ecx
f010342a:	89 75 08             	mov    %esi,0x8(%ebp)
f010342d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103430:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103433:	89 cb                	mov    %ecx,%ebx
f0103435:	eb 4d                	jmp    f0103484 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103437:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010343b:	74 1b                	je     f0103458 <vprintfmt+0x213>
f010343d:	0f be c0             	movsbl %al,%eax
f0103440:	83 e8 20             	sub    $0x20,%eax
f0103443:	83 f8 5e             	cmp    $0x5e,%eax
f0103446:	76 10                	jbe    f0103458 <vprintfmt+0x213>
					putch('?', putdat);
f0103448:	83 ec 08             	sub    $0x8,%esp
f010344b:	ff 75 0c             	pushl  0xc(%ebp)
f010344e:	6a 3f                	push   $0x3f
f0103450:	ff 55 08             	call   *0x8(%ebp)
f0103453:	83 c4 10             	add    $0x10,%esp
f0103456:	eb 0d                	jmp    f0103465 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103458:	83 ec 08             	sub    $0x8,%esp
f010345b:	ff 75 0c             	pushl  0xc(%ebp)
f010345e:	52                   	push   %edx
f010345f:	ff 55 08             	call   *0x8(%ebp)
f0103462:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103465:	83 eb 01             	sub    $0x1,%ebx
f0103468:	eb 1a                	jmp    f0103484 <vprintfmt+0x23f>
f010346a:	89 75 08             	mov    %esi,0x8(%ebp)
f010346d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103470:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103473:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103476:	eb 0c                	jmp    f0103484 <vprintfmt+0x23f>
f0103478:	89 75 08             	mov    %esi,0x8(%ebp)
f010347b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010347e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103481:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103484:	83 c7 01             	add    $0x1,%edi
f0103487:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010348b:	0f be d0             	movsbl %al,%edx
f010348e:	85 d2                	test   %edx,%edx
f0103490:	74 23                	je     f01034b5 <vprintfmt+0x270>
f0103492:	85 f6                	test   %esi,%esi
f0103494:	78 a1                	js     f0103437 <vprintfmt+0x1f2>
f0103496:	83 ee 01             	sub    $0x1,%esi
f0103499:	79 9c                	jns    f0103437 <vprintfmt+0x1f2>
f010349b:	89 df                	mov    %ebx,%edi
f010349d:	8b 75 08             	mov    0x8(%ebp),%esi
f01034a0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01034a3:	eb 18                	jmp    f01034bd <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01034a5:	83 ec 08             	sub    $0x8,%esp
f01034a8:	53                   	push   %ebx
f01034a9:	6a 20                	push   $0x20
f01034ab:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01034ad:	83 ef 01             	sub    $0x1,%edi
f01034b0:	83 c4 10             	add    $0x10,%esp
f01034b3:	eb 08                	jmp    f01034bd <vprintfmt+0x278>
f01034b5:	89 df                	mov    %ebx,%edi
f01034b7:	8b 75 08             	mov    0x8(%ebp),%esi
f01034ba:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01034bd:	85 ff                	test   %edi,%edi
f01034bf:	7f e4                	jg     f01034a5 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034c1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01034c4:	e9 a2 fd ff ff       	jmp    f010326b <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01034c9:	83 fa 01             	cmp    $0x1,%edx
f01034cc:	7e 16                	jle    f01034e4 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01034ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01034d1:	8d 50 08             	lea    0x8(%eax),%edx
f01034d4:	89 55 14             	mov    %edx,0x14(%ebp)
f01034d7:	8b 50 04             	mov    0x4(%eax),%edx
f01034da:	8b 00                	mov    (%eax),%eax
f01034dc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01034df:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01034e2:	eb 32                	jmp    f0103516 <vprintfmt+0x2d1>
	else if (lflag)
f01034e4:	85 d2                	test   %edx,%edx
f01034e6:	74 18                	je     f0103500 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f01034e8:	8b 45 14             	mov    0x14(%ebp),%eax
f01034eb:	8d 50 04             	lea    0x4(%eax),%edx
f01034ee:	89 55 14             	mov    %edx,0x14(%ebp)
f01034f1:	8b 00                	mov    (%eax),%eax
f01034f3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01034f6:	89 c1                	mov    %eax,%ecx
f01034f8:	c1 f9 1f             	sar    $0x1f,%ecx
f01034fb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01034fe:	eb 16                	jmp    f0103516 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0103500:	8b 45 14             	mov    0x14(%ebp),%eax
f0103503:	8d 50 04             	lea    0x4(%eax),%edx
f0103506:	89 55 14             	mov    %edx,0x14(%ebp)
f0103509:	8b 00                	mov    (%eax),%eax
f010350b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010350e:	89 c1                	mov    %eax,%ecx
f0103510:	c1 f9 1f             	sar    $0x1f,%ecx
f0103513:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103516:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103519:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010351c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103521:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103525:	79 74                	jns    f010359b <vprintfmt+0x356>
				putch('-', putdat);
f0103527:	83 ec 08             	sub    $0x8,%esp
f010352a:	53                   	push   %ebx
f010352b:	6a 2d                	push   $0x2d
f010352d:	ff d6                	call   *%esi
				num = -(long long) num;
f010352f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103532:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103535:	f7 d8                	neg    %eax
f0103537:	83 d2 00             	adc    $0x0,%edx
f010353a:	f7 da                	neg    %edx
f010353c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010353f:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103544:	eb 55                	jmp    f010359b <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103546:	8d 45 14             	lea    0x14(%ebp),%eax
f0103549:	e8 83 fc ff ff       	call   f01031d1 <getuint>
			base = 10;
f010354e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103553:	eb 46                	jmp    f010359b <vprintfmt+0x356>
			// Replace this with your code.
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f0103555:	8d 45 14             	lea    0x14(%ebp),%eax
f0103558:	e8 74 fc ff ff       	call   f01031d1 <getuint>
			base = 8;
f010355d:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103562:	eb 37                	jmp    f010359b <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0103564:	83 ec 08             	sub    $0x8,%esp
f0103567:	53                   	push   %ebx
f0103568:	6a 30                	push   $0x30
f010356a:	ff d6                	call   *%esi
			putch('x', putdat);
f010356c:	83 c4 08             	add    $0x8,%esp
f010356f:	53                   	push   %ebx
f0103570:	6a 78                	push   $0x78
f0103572:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103574:	8b 45 14             	mov    0x14(%ebp),%eax
f0103577:	8d 50 04             	lea    0x4(%eax),%edx
f010357a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010357d:	8b 00                	mov    (%eax),%eax
f010357f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103584:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103587:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010358c:	eb 0d                	jmp    f010359b <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010358e:	8d 45 14             	lea    0x14(%ebp),%eax
f0103591:	e8 3b fc ff ff       	call   f01031d1 <getuint>
			base = 16;
f0103596:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010359b:	83 ec 0c             	sub    $0xc,%esp
f010359e:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01035a2:	57                   	push   %edi
f01035a3:	ff 75 e0             	pushl  -0x20(%ebp)
f01035a6:	51                   	push   %ecx
f01035a7:	52                   	push   %edx
f01035a8:	50                   	push   %eax
f01035a9:	89 da                	mov    %ebx,%edx
f01035ab:	89 f0                	mov    %esi,%eax
f01035ad:	e8 70 fb ff ff       	call   f0103122 <printnum>
			break;
f01035b2:	83 c4 20             	add    $0x20,%esp
f01035b5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01035b8:	e9 ae fc ff ff       	jmp    f010326b <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01035bd:	83 ec 08             	sub    $0x8,%esp
f01035c0:	53                   	push   %ebx
f01035c1:	51                   	push   %ecx
f01035c2:	ff d6                	call   *%esi
			break;
f01035c4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035c7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01035ca:	e9 9c fc ff ff       	jmp    f010326b <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01035cf:	83 ec 08             	sub    $0x8,%esp
f01035d2:	53                   	push   %ebx
f01035d3:	6a 25                	push   $0x25
f01035d5:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01035d7:	83 c4 10             	add    $0x10,%esp
f01035da:	eb 03                	jmp    f01035df <vprintfmt+0x39a>
f01035dc:	83 ef 01             	sub    $0x1,%edi
f01035df:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01035e3:	75 f7                	jne    f01035dc <vprintfmt+0x397>
f01035e5:	e9 81 fc ff ff       	jmp    f010326b <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01035ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01035ed:	5b                   	pop    %ebx
f01035ee:	5e                   	pop    %esi
f01035ef:	5f                   	pop    %edi
f01035f0:	5d                   	pop    %ebp
f01035f1:	c3                   	ret    

f01035f2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01035f2:	55                   	push   %ebp
f01035f3:	89 e5                	mov    %esp,%ebp
f01035f5:	83 ec 18             	sub    $0x18,%esp
f01035f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01035fb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01035fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103601:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103605:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103608:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010360f:	85 c0                	test   %eax,%eax
f0103611:	74 26                	je     f0103639 <vsnprintf+0x47>
f0103613:	85 d2                	test   %edx,%edx
f0103615:	7e 22                	jle    f0103639 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103617:	ff 75 14             	pushl  0x14(%ebp)
f010361a:	ff 75 10             	pushl  0x10(%ebp)
f010361d:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103620:	50                   	push   %eax
f0103621:	68 0b 32 10 f0       	push   $0xf010320b
f0103626:	e8 1a fc ff ff       	call   f0103245 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010362b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010362e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103631:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103634:	83 c4 10             	add    $0x10,%esp
f0103637:	eb 05                	jmp    f010363e <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103639:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010363e:	c9                   	leave  
f010363f:	c3                   	ret    

f0103640 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103640:	55                   	push   %ebp
f0103641:	89 e5                	mov    %esp,%ebp
f0103643:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103646:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103649:	50                   	push   %eax
f010364a:	ff 75 10             	pushl  0x10(%ebp)
f010364d:	ff 75 0c             	pushl  0xc(%ebp)
f0103650:	ff 75 08             	pushl  0x8(%ebp)
f0103653:	e8 9a ff ff ff       	call   f01035f2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103658:	c9                   	leave  
f0103659:	c3                   	ret    

f010365a <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010365a:	55                   	push   %ebp
f010365b:	89 e5                	mov    %esp,%ebp
f010365d:	57                   	push   %edi
f010365e:	56                   	push   %esi
f010365f:	53                   	push   %ebx
f0103660:	83 ec 0c             	sub    $0xc,%esp
f0103663:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103666:	85 c0                	test   %eax,%eax
f0103668:	74 11                	je     f010367b <readline+0x21>
		cprintf("%s", prompt);
f010366a:	83 ec 08             	sub    $0x8,%esp
f010366d:	50                   	push   %eax
f010366e:	68 53 46 10 f0       	push   $0xf0104653
f0103673:	e8 7e f7 ff ff       	call   f0102df6 <cprintf>
f0103678:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010367b:	83 ec 0c             	sub    $0xc,%esp
f010367e:	6a 00                	push   $0x0
f0103680:	e8 9c cf ff ff       	call   f0100621 <iscons>
f0103685:	89 c7                	mov    %eax,%edi
f0103687:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010368a:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010368f:	e8 7c cf ff ff       	call   f0100610 <getchar>
f0103694:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103696:	85 c0                	test   %eax,%eax
f0103698:	79 18                	jns    f01036b2 <readline+0x58>
			cprintf("read error: %e\n", c);
f010369a:	83 ec 08             	sub    $0x8,%esp
f010369d:	50                   	push   %eax
f010369e:	68 b0 52 10 f0       	push   $0xf01052b0
f01036a3:	e8 4e f7 ff ff       	call   f0102df6 <cprintf>
			return NULL;
f01036a8:	83 c4 10             	add    $0x10,%esp
f01036ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01036b0:	eb 79                	jmp    f010372b <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01036b2:	83 f8 08             	cmp    $0x8,%eax
f01036b5:	0f 94 c2             	sete   %dl
f01036b8:	83 f8 7f             	cmp    $0x7f,%eax
f01036bb:	0f 94 c0             	sete   %al
f01036be:	08 c2                	or     %al,%dl
f01036c0:	74 1a                	je     f01036dc <readline+0x82>
f01036c2:	85 f6                	test   %esi,%esi
f01036c4:	7e 16                	jle    f01036dc <readline+0x82>
			if (echoing)
f01036c6:	85 ff                	test   %edi,%edi
f01036c8:	74 0d                	je     f01036d7 <readline+0x7d>
				cputchar('\b');
f01036ca:	83 ec 0c             	sub    $0xc,%esp
f01036cd:	6a 08                	push   $0x8
f01036cf:	e8 2c cf ff ff       	call   f0100600 <cputchar>
f01036d4:	83 c4 10             	add    $0x10,%esp
			i--;
f01036d7:	83 ee 01             	sub    $0x1,%esi
f01036da:	eb b3                	jmp    f010368f <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01036dc:	83 fb 1f             	cmp    $0x1f,%ebx
f01036df:	7e 23                	jle    f0103704 <readline+0xaa>
f01036e1:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01036e7:	7f 1b                	jg     f0103704 <readline+0xaa>
			if (echoing)
f01036e9:	85 ff                	test   %edi,%edi
f01036eb:	74 0c                	je     f01036f9 <readline+0x9f>
				cputchar(c);
f01036ed:	83 ec 0c             	sub    $0xc,%esp
f01036f0:	53                   	push   %ebx
f01036f1:	e8 0a cf ff ff       	call   f0100600 <cputchar>
f01036f6:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01036f9:	88 9e 60 85 11 f0    	mov    %bl,-0xfee7aa0(%esi)
f01036ff:	8d 76 01             	lea    0x1(%esi),%esi
f0103702:	eb 8b                	jmp    f010368f <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103704:	83 fb 0a             	cmp    $0xa,%ebx
f0103707:	74 05                	je     f010370e <readline+0xb4>
f0103709:	83 fb 0d             	cmp    $0xd,%ebx
f010370c:	75 81                	jne    f010368f <readline+0x35>
			if (echoing)
f010370e:	85 ff                	test   %edi,%edi
f0103710:	74 0d                	je     f010371f <readline+0xc5>
				cputchar('\n');
f0103712:	83 ec 0c             	sub    $0xc,%esp
f0103715:	6a 0a                	push   $0xa
f0103717:	e8 e4 ce ff ff       	call   f0100600 <cputchar>
f010371c:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010371f:	c6 86 60 85 11 f0 00 	movb   $0x0,-0xfee7aa0(%esi)
			return buf;
f0103726:	b8 60 85 11 f0       	mov    $0xf0118560,%eax
		}
	}
}
f010372b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010372e:	5b                   	pop    %ebx
f010372f:	5e                   	pop    %esi
f0103730:	5f                   	pop    %edi
f0103731:	5d                   	pop    %ebp
f0103732:	c3                   	ret    

f0103733 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103733:	55                   	push   %ebp
f0103734:	89 e5                	mov    %esp,%ebp
f0103736:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103739:	b8 00 00 00 00       	mov    $0x0,%eax
f010373e:	eb 03                	jmp    f0103743 <strlen+0x10>
		n++;
f0103740:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103743:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103747:	75 f7                	jne    f0103740 <strlen+0xd>
		n++;
	return n;
}
f0103749:	5d                   	pop    %ebp
f010374a:	c3                   	ret    

f010374b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010374b:	55                   	push   %ebp
f010374c:	89 e5                	mov    %esp,%ebp
f010374e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103751:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103754:	ba 00 00 00 00       	mov    $0x0,%edx
f0103759:	eb 03                	jmp    f010375e <strnlen+0x13>
		n++;
f010375b:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010375e:	39 c2                	cmp    %eax,%edx
f0103760:	74 08                	je     f010376a <strnlen+0x1f>
f0103762:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103766:	75 f3                	jne    f010375b <strnlen+0x10>
f0103768:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010376a:	5d                   	pop    %ebp
f010376b:	c3                   	ret    

f010376c <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010376c:	55                   	push   %ebp
f010376d:	89 e5                	mov    %esp,%ebp
f010376f:	53                   	push   %ebx
f0103770:	8b 45 08             	mov    0x8(%ebp),%eax
f0103773:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103776:	89 c2                	mov    %eax,%edx
f0103778:	83 c2 01             	add    $0x1,%edx
f010377b:	83 c1 01             	add    $0x1,%ecx
f010377e:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103782:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103785:	84 db                	test   %bl,%bl
f0103787:	75 ef                	jne    f0103778 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103789:	5b                   	pop    %ebx
f010378a:	5d                   	pop    %ebp
f010378b:	c3                   	ret    

f010378c <strcat>:

char *
strcat(char *dst, const char *src)
{
f010378c:	55                   	push   %ebp
f010378d:	89 e5                	mov    %esp,%ebp
f010378f:	53                   	push   %ebx
f0103790:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103793:	53                   	push   %ebx
f0103794:	e8 9a ff ff ff       	call   f0103733 <strlen>
f0103799:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010379c:	ff 75 0c             	pushl  0xc(%ebp)
f010379f:	01 d8                	add    %ebx,%eax
f01037a1:	50                   	push   %eax
f01037a2:	e8 c5 ff ff ff       	call   f010376c <strcpy>
	return dst;
}
f01037a7:	89 d8                	mov    %ebx,%eax
f01037a9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01037ac:	c9                   	leave  
f01037ad:	c3                   	ret    

f01037ae <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01037ae:	55                   	push   %ebp
f01037af:	89 e5                	mov    %esp,%ebp
f01037b1:	56                   	push   %esi
f01037b2:	53                   	push   %ebx
f01037b3:	8b 75 08             	mov    0x8(%ebp),%esi
f01037b6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01037b9:	89 f3                	mov    %esi,%ebx
f01037bb:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01037be:	89 f2                	mov    %esi,%edx
f01037c0:	eb 0f                	jmp    f01037d1 <strncpy+0x23>
		*dst++ = *src;
f01037c2:	83 c2 01             	add    $0x1,%edx
f01037c5:	0f b6 01             	movzbl (%ecx),%eax
f01037c8:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01037cb:	80 39 01             	cmpb   $0x1,(%ecx)
f01037ce:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01037d1:	39 da                	cmp    %ebx,%edx
f01037d3:	75 ed                	jne    f01037c2 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01037d5:	89 f0                	mov    %esi,%eax
f01037d7:	5b                   	pop    %ebx
f01037d8:	5e                   	pop    %esi
f01037d9:	5d                   	pop    %ebp
f01037da:	c3                   	ret    

f01037db <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01037db:	55                   	push   %ebp
f01037dc:	89 e5                	mov    %esp,%ebp
f01037de:	56                   	push   %esi
f01037df:	53                   	push   %ebx
f01037e0:	8b 75 08             	mov    0x8(%ebp),%esi
f01037e3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01037e6:	8b 55 10             	mov    0x10(%ebp),%edx
f01037e9:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01037eb:	85 d2                	test   %edx,%edx
f01037ed:	74 21                	je     f0103810 <strlcpy+0x35>
f01037ef:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01037f3:	89 f2                	mov    %esi,%edx
f01037f5:	eb 09                	jmp    f0103800 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01037f7:	83 c2 01             	add    $0x1,%edx
f01037fa:	83 c1 01             	add    $0x1,%ecx
f01037fd:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103800:	39 c2                	cmp    %eax,%edx
f0103802:	74 09                	je     f010380d <strlcpy+0x32>
f0103804:	0f b6 19             	movzbl (%ecx),%ebx
f0103807:	84 db                	test   %bl,%bl
f0103809:	75 ec                	jne    f01037f7 <strlcpy+0x1c>
f010380b:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010380d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103810:	29 f0                	sub    %esi,%eax
}
f0103812:	5b                   	pop    %ebx
f0103813:	5e                   	pop    %esi
f0103814:	5d                   	pop    %ebp
f0103815:	c3                   	ret    

f0103816 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103816:	55                   	push   %ebp
f0103817:	89 e5                	mov    %esp,%ebp
f0103819:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010381c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010381f:	eb 06                	jmp    f0103827 <strcmp+0x11>
		p++, q++;
f0103821:	83 c1 01             	add    $0x1,%ecx
f0103824:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103827:	0f b6 01             	movzbl (%ecx),%eax
f010382a:	84 c0                	test   %al,%al
f010382c:	74 04                	je     f0103832 <strcmp+0x1c>
f010382e:	3a 02                	cmp    (%edx),%al
f0103830:	74 ef                	je     f0103821 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103832:	0f b6 c0             	movzbl %al,%eax
f0103835:	0f b6 12             	movzbl (%edx),%edx
f0103838:	29 d0                	sub    %edx,%eax
}
f010383a:	5d                   	pop    %ebp
f010383b:	c3                   	ret    

f010383c <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010383c:	55                   	push   %ebp
f010383d:	89 e5                	mov    %esp,%ebp
f010383f:	53                   	push   %ebx
f0103840:	8b 45 08             	mov    0x8(%ebp),%eax
f0103843:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103846:	89 c3                	mov    %eax,%ebx
f0103848:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010384b:	eb 06                	jmp    f0103853 <strncmp+0x17>
		n--, p++, q++;
f010384d:	83 c0 01             	add    $0x1,%eax
f0103850:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103853:	39 d8                	cmp    %ebx,%eax
f0103855:	74 15                	je     f010386c <strncmp+0x30>
f0103857:	0f b6 08             	movzbl (%eax),%ecx
f010385a:	84 c9                	test   %cl,%cl
f010385c:	74 04                	je     f0103862 <strncmp+0x26>
f010385e:	3a 0a                	cmp    (%edx),%cl
f0103860:	74 eb                	je     f010384d <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103862:	0f b6 00             	movzbl (%eax),%eax
f0103865:	0f b6 12             	movzbl (%edx),%edx
f0103868:	29 d0                	sub    %edx,%eax
f010386a:	eb 05                	jmp    f0103871 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010386c:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103871:	5b                   	pop    %ebx
f0103872:	5d                   	pop    %ebp
f0103873:	c3                   	ret    

f0103874 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103874:	55                   	push   %ebp
f0103875:	89 e5                	mov    %esp,%ebp
f0103877:	8b 45 08             	mov    0x8(%ebp),%eax
f010387a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010387e:	eb 07                	jmp    f0103887 <strchr+0x13>
		if (*s == c)
f0103880:	38 ca                	cmp    %cl,%dl
f0103882:	74 0f                	je     f0103893 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103884:	83 c0 01             	add    $0x1,%eax
f0103887:	0f b6 10             	movzbl (%eax),%edx
f010388a:	84 d2                	test   %dl,%dl
f010388c:	75 f2                	jne    f0103880 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010388e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103893:	5d                   	pop    %ebp
f0103894:	c3                   	ret    

f0103895 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103895:	55                   	push   %ebp
f0103896:	89 e5                	mov    %esp,%ebp
f0103898:	8b 45 08             	mov    0x8(%ebp),%eax
f010389b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010389f:	eb 03                	jmp    f01038a4 <strfind+0xf>
f01038a1:	83 c0 01             	add    $0x1,%eax
f01038a4:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01038a7:	38 ca                	cmp    %cl,%dl
f01038a9:	74 04                	je     f01038af <strfind+0x1a>
f01038ab:	84 d2                	test   %dl,%dl
f01038ad:	75 f2                	jne    f01038a1 <strfind+0xc>
			break;
	return (char *) s;
}
f01038af:	5d                   	pop    %ebp
f01038b0:	c3                   	ret    

f01038b1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01038b1:	55                   	push   %ebp
f01038b2:	89 e5                	mov    %esp,%ebp
f01038b4:	57                   	push   %edi
f01038b5:	56                   	push   %esi
f01038b6:	53                   	push   %ebx
f01038b7:	8b 7d 08             	mov    0x8(%ebp),%edi
f01038ba:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01038bd:	85 c9                	test   %ecx,%ecx
f01038bf:	74 36                	je     f01038f7 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01038c1:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01038c7:	75 28                	jne    f01038f1 <memset+0x40>
f01038c9:	f6 c1 03             	test   $0x3,%cl
f01038cc:	75 23                	jne    f01038f1 <memset+0x40>
		c &= 0xFF;
f01038ce:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01038d2:	89 d3                	mov    %edx,%ebx
f01038d4:	c1 e3 08             	shl    $0x8,%ebx
f01038d7:	89 d6                	mov    %edx,%esi
f01038d9:	c1 e6 18             	shl    $0x18,%esi
f01038dc:	89 d0                	mov    %edx,%eax
f01038de:	c1 e0 10             	shl    $0x10,%eax
f01038e1:	09 f0                	or     %esi,%eax
f01038e3:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01038e5:	89 d8                	mov    %ebx,%eax
f01038e7:	09 d0                	or     %edx,%eax
f01038e9:	c1 e9 02             	shr    $0x2,%ecx
f01038ec:	fc                   	cld    
f01038ed:	f3 ab                	rep stos %eax,%es:(%edi)
f01038ef:	eb 06                	jmp    f01038f7 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01038f1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038f4:	fc                   	cld    
f01038f5:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01038f7:	89 f8                	mov    %edi,%eax
f01038f9:	5b                   	pop    %ebx
f01038fa:	5e                   	pop    %esi
f01038fb:	5f                   	pop    %edi
f01038fc:	5d                   	pop    %ebp
f01038fd:	c3                   	ret    

f01038fe <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01038fe:	55                   	push   %ebp
f01038ff:	89 e5                	mov    %esp,%ebp
f0103901:	57                   	push   %edi
f0103902:	56                   	push   %esi
f0103903:	8b 45 08             	mov    0x8(%ebp),%eax
f0103906:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103909:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010390c:	39 c6                	cmp    %eax,%esi
f010390e:	73 35                	jae    f0103945 <memmove+0x47>
f0103910:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103913:	39 d0                	cmp    %edx,%eax
f0103915:	73 2e                	jae    f0103945 <memmove+0x47>
		s += n;
		d += n;
f0103917:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010391a:	89 d6                	mov    %edx,%esi
f010391c:	09 fe                	or     %edi,%esi
f010391e:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103924:	75 13                	jne    f0103939 <memmove+0x3b>
f0103926:	f6 c1 03             	test   $0x3,%cl
f0103929:	75 0e                	jne    f0103939 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010392b:	83 ef 04             	sub    $0x4,%edi
f010392e:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103931:	c1 e9 02             	shr    $0x2,%ecx
f0103934:	fd                   	std    
f0103935:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103937:	eb 09                	jmp    f0103942 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103939:	83 ef 01             	sub    $0x1,%edi
f010393c:	8d 72 ff             	lea    -0x1(%edx),%esi
f010393f:	fd                   	std    
f0103940:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103942:	fc                   	cld    
f0103943:	eb 1d                	jmp    f0103962 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103945:	89 f2                	mov    %esi,%edx
f0103947:	09 c2                	or     %eax,%edx
f0103949:	f6 c2 03             	test   $0x3,%dl
f010394c:	75 0f                	jne    f010395d <memmove+0x5f>
f010394e:	f6 c1 03             	test   $0x3,%cl
f0103951:	75 0a                	jne    f010395d <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103953:	c1 e9 02             	shr    $0x2,%ecx
f0103956:	89 c7                	mov    %eax,%edi
f0103958:	fc                   	cld    
f0103959:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010395b:	eb 05                	jmp    f0103962 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010395d:	89 c7                	mov    %eax,%edi
f010395f:	fc                   	cld    
f0103960:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103962:	5e                   	pop    %esi
f0103963:	5f                   	pop    %edi
f0103964:	5d                   	pop    %ebp
f0103965:	c3                   	ret    

f0103966 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103966:	55                   	push   %ebp
f0103967:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103969:	ff 75 10             	pushl  0x10(%ebp)
f010396c:	ff 75 0c             	pushl  0xc(%ebp)
f010396f:	ff 75 08             	pushl  0x8(%ebp)
f0103972:	e8 87 ff ff ff       	call   f01038fe <memmove>
}
f0103977:	c9                   	leave  
f0103978:	c3                   	ret    

f0103979 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103979:	55                   	push   %ebp
f010397a:	89 e5                	mov    %esp,%ebp
f010397c:	56                   	push   %esi
f010397d:	53                   	push   %ebx
f010397e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103981:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103984:	89 c6                	mov    %eax,%esi
f0103986:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103989:	eb 1a                	jmp    f01039a5 <memcmp+0x2c>
		if (*s1 != *s2)
f010398b:	0f b6 08             	movzbl (%eax),%ecx
f010398e:	0f b6 1a             	movzbl (%edx),%ebx
f0103991:	38 d9                	cmp    %bl,%cl
f0103993:	74 0a                	je     f010399f <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103995:	0f b6 c1             	movzbl %cl,%eax
f0103998:	0f b6 db             	movzbl %bl,%ebx
f010399b:	29 d8                	sub    %ebx,%eax
f010399d:	eb 0f                	jmp    f01039ae <memcmp+0x35>
		s1++, s2++;
f010399f:	83 c0 01             	add    $0x1,%eax
f01039a2:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01039a5:	39 f0                	cmp    %esi,%eax
f01039a7:	75 e2                	jne    f010398b <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01039a9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01039ae:	5b                   	pop    %ebx
f01039af:	5e                   	pop    %esi
f01039b0:	5d                   	pop    %ebp
f01039b1:	c3                   	ret    

f01039b2 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01039b2:	55                   	push   %ebp
f01039b3:	89 e5                	mov    %esp,%ebp
f01039b5:	53                   	push   %ebx
f01039b6:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01039b9:	89 c1                	mov    %eax,%ecx
f01039bb:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01039be:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01039c2:	eb 0a                	jmp    f01039ce <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01039c4:	0f b6 10             	movzbl (%eax),%edx
f01039c7:	39 da                	cmp    %ebx,%edx
f01039c9:	74 07                	je     f01039d2 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01039cb:	83 c0 01             	add    $0x1,%eax
f01039ce:	39 c8                	cmp    %ecx,%eax
f01039d0:	72 f2                	jb     f01039c4 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01039d2:	5b                   	pop    %ebx
f01039d3:	5d                   	pop    %ebp
f01039d4:	c3                   	ret    

f01039d5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01039d5:	55                   	push   %ebp
f01039d6:	89 e5                	mov    %esp,%ebp
f01039d8:	57                   	push   %edi
f01039d9:	56                   	push   %esi
f01039da:	53                   	push   %ebx
f01039db:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01039de:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01039e1:	eb 03                	jmp    f01039e6 <strtol+0x11>
		s++;
f01039e3:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01039e6:	0f b6 01             	movzbl (%ecx),%eax
f01039e9:	3c 20                	cmp    $0x20,%al
f01039eb:	74 f6                	je     f01039e3 <strtol+0xe>
f01039ed:	3c 09                	cmp    $0x9,%al
f01039ef:	74 f2                	je     f01039e3 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01039f1:	3c 2b                	cmp    $0x2b,%al
f01039f3:	75 0a                	jne    f01039ff <strtol+0x2a>
		s++;
f01039f5:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01039f8:	bf 00 00 00 00       	mov    $0x0,%edi
f01039fd:	eb 11                	jmp    f0103a10 <strtol+0x3b>
f01039ff:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103a04:	3c 2d                	cmp    $0x2d,%al
f0103a06:	75 08                	jne    f0103a10 <strtol+0x3b>
		s++, neg = 1;
f0103a08:	83 c1 01             	add    $0x1,%ecx
f0103a0b:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103a10:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103a16:	75 15                	jne    f0103a2d <strtol+0x58>
f0103a18:	80 39 30             	cmpb   $0x30,(%ecx)
f0103a1b:	75 10                	jne    f0103a2d <strtol+0x58>
f0103a1d:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103a21:	75 7c                	jne    f0103a9f <strtol+0xca>
		s += 2, base = 16;
f0103a23:	83 c1 02             	add    $0x2,%ecx
f0103a26:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103a2b:	eb 16                	jmp    f0103a43 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103a2d:	85 db                	test   %ebx,%ebx
f0103a2f:	75 12                	jne    f0103a43 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103a31:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103a36:	80 39 30             	cmpb   $0x30,(%ecx)
f0103a39:	75 08                	jne    f0103a43 <strtol+0x6e>
		s++, base = 8;
f0103a3b:	83 c1 01             	add    $0x1,%ecx
f0103a3e:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103a43:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a48:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103a4b:	0f b6 11             	movzbl (%ecx),%edx
f0103a4e:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103a51:	89 f3                	mov    %esi,%ebx
f0103a53:	80 fb 09             	cmp    $0x9,%bl
f0103a56:	77 08                	ja     f0103a60 <strtol+0x8b>
			dig = *s - '0';
f0103a58:	0f be d2             	movsbl %dl,%edx
f0103a5b:	83 ea 30             	sub    $0x30,%edx
f0103a5e:	eb 22                	jmp    f0103a82 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103a60:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103a63:	89 f3                	mov    %esi,%ebx
f0103a65:	80 fb 19             	cmp    $0x19,%bl
f0103a68:	77 08                	ja     f0103a72 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103a6a:	0f be d2             	movsbl %dl,%edx
f0103a6d:	83 ea 57             	sub    $0x57,%edx
f0103a70:	eb 10                	jmp    f0103a82 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103a72:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103a75:	89 f3                	mov    %esi,%ebx
f0103a77:	80 fb 19             	cmp    $0x19,%bl
f0103a7a:	77 16                	ja     f0103a92 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103a7c:	0f be d2             	movsbl %dl,%edx
f0103a7f:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103a82:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103a85:	7d 0b                	jge    f0103a92 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103a87:	83 c1 01             	add    $0x1,%ecx
f0103a8a:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103a8e:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103a90:	eb b9                	jmp    f0103a4b <strtol+0x76>

	if (endptr)
f0103a92:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103a96:	74 0d                	je     f0103aa5 <strtol+0xd0>
		*endptr = (char *) s;
f0103a98:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a9b:	89 0e                	mov    %ecx,(%esi)
f0103a9d:	eb 06                	jmp    f0103aa5 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103a9f:	85 db                	test   %ebx,%ebx
f0103aa1:	74 98                	je     f0103a3b <strtol+0x66>
f0103aa3:	eb 9e                	jmp    f0103a43 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103aa5:	89 c2                	mov    %eax,%edx
f0103aa7:	f7 da                	neg    %edx
f0103aa9:	85 ff                	test   %edi,%edi
f0103aab:	0f 45 c2             	cmovne %edx,%eax
}
f0103aae:	5b                   	pop    %ebx
f0103aaf:	5e                   	pop    %esi
f0103ab0:	5f                   	pop    %edi
f0103ab1:	5d                   	pop    %ebp
f0103ab2:	c3                   	ret    
f0103ab3:	66 90                	xchg   %ax,%ax
f0103ab5:	66 90                	xchg   %ax,%ax
f0103ab7:	66 90                	xchg   %ax,%ax
f0103ab9:	66 90                	xchg   %ax,%ax
f0103abb:	66 90                	xchg   %ax,%ax
f0103abd:	66 90                	xchg   %ax,%ax
f0103abf:	90                   	nop

f0103ac0 <__udivdi3>:
f0103ac0:	55                   	push   %ebp
f0103ac1:	57                   	push   %edi
f0103ac2:	56                   	push   %esi
f0103ac3:	53                   	push   %ebx
f0103ac4:	83 ec 1c             	sub    $0x1c,%esp
f0103ac7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0103acb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0103acf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103ad3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103ad7:	85 f6                	test   %esi,%esi
f0103ad9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103add:	89 ca                	mov    %ecx,%edx
f0103adf:	89 f8                	mov    %edi,%eax
f0103ae1:	75 3d                	jne    f0103b20 <__udivdi3+0x60>
f0103ae3:	39 cf                	cmp    %ecx,%edi
f0103ae5:	0f 87 c5 00 00 00    	ja     f0103bb0 <__udivdi3+0xf0>
f0103aeb:	85 ff                	test   %edi,%edi
f0103aed:	89 fd                	mov    %edi,%ebp
f0103aef:	75 0b                	jne    f0103afc <__udivdi3+0x3c>
f0103af1:	b8 01 00 00 00       	mov    $0x1,%eax
f0103af6:	31 d2                	xor    %edx,%edx
f0103af8:	f7 f7                	div    %edi
f0103afa:	89 c5                	mov    %eax,%ebp
f0103afc:	89 c8                	mov    %ecx,%eax
f0103afe:	31 d2                	xor    %edx,%edx
f0103b00:	f7 f5                	div    %ebp
f0103b02:	89 c1                	mov    %eax,%ecx
f0103b04:	89 d8                	mov    %ebx,%eax
f0103b06:	89 cf                	mov    %ecx,%edi
f0103b08:	f7 f5                	div    %ebp
f0103b0a:	89 c3                	mov    %eax,%ebx
f0103b0c:	89 d8                	mov    %ebx,%eax
f0103b0e:	89 fa                	mov    %edi,%edx
f0103b10:	83 c4 1c             	add    $0x1c,%esp
f0103b13:	5b                   	pop    %ebx
f0103b14:	5e                   	pop    %esi
f0103b15:	5f                   	pop    %edi
f0103b16:	5d                   	pop    %ebp
f0103b17:	c3                   	ret    
f0103b18:	90                   	nop
f0103b19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103b20:	39 ce                	cmp    %ecx,%esi
f0103b22:	77 74                	ja     f0103b98 <__udivdi3+0xd8>
f0103b24:	0f bd fe             	bsr    %esi,%edi
f0103b27:	83 f7 1f             	xor    $0x1f,%edi
f0103b2a:	0f 84 98 00 00 00    	je     f0103bc8 <__udivdi3+0x108>
f0103b30:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103b35:	89 f9                	mov    %edi,%ecx
f0103b37:	89 c5                	mov    %eax,%ebp
f0103b39:	29 fb                	sub    %edi,%ebx
f0103b3b:	d3 e6                	shl    %cl,%esi
f0103b3d:	89 d9                	mov    %ebx,%ecx
f0103b3f:	d3 ed                	shr    %cl,%ebp
f0103b41:	89 f9                	mov    %edi,%ecx
f0103b43:	d3 e0                	shl    %cl,%eax
f0103b45:	09 ee                	or     %ebp,%esi
f0103b47:	89 d9                	mov    %ebx,%ecx
f0103b49:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103b4d:	89 d5                	mov    %edx,%ebp
f0103b4f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103b53:	d3 ed                	shr    %cl,%ebp
f0103b55:	89 f9                	mov    %edi,%ecx
f0103b57:	d3 e2                	shl    %cl,%edx
f0103b59:	89 d9                	mov    %ebx,%ecx
f0103b5b:	d3 e8                	shr    %cl,%eax
f0103b5d:	09 c2                	or     %eax,%edx
f0103b5f:	89 d0                	mov    %edx,%eax
f0103b61:	89 ea                	mov    %ebp,%edx
f0103b63:	f7 f6                	div    %esi
f0103b65:	89 d5                	mov    %edx,%ebp
f0103b67:	89 c3                	mov    %eax,%ebx
f0103b69:	f7 64 24 0c          	mull   0xc(%esp)
f0103b6d:	39 d5                	cmp    %edx,%ebp
f0103b6f:	72 10                	jb     f0103b81 <__udivdi3+0xc1>
f0103b71:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103b75:	89 f9                	mov    %edi,%ecx
f0103b77:	d3 e6                	shl    %cl,%esi
f0103b79:	39 c6                	cmp    %eax,%esi
f0103b7b:	73 07                	jae    f0103b84 <__udivdi3+0xc4>
f0103b7d:	39 d5                	cmp    %edx,%ebp
f0103b7f:	75 03                	jne    f0103b84 <__udivdi3+0xc4>
f0103b81:	83 eb 01             	sub    $0x1,%ebx
f0103b84:	31 ff                	xor    %edi,%edi
f0103b86:	89 d8                	mov    %ebx,%eax
f0103b88:	89 fa                	mov    %edi,%edx
f0103b8a:	83 c4 1c             	add    $0x1c,%esp
f0103b8d:	5b                   	pop    %ebx
f0103b8e:	5e                   	pop    %esi
f0103b8f:	5f                   	pop    %edi
f0103b90:	5d                   	pop    %ebp
f0103b91:	c3                   	ret    
f0103b92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103b98:	31 ff                	xor    %edi,%edi
f0103b9a:	31 db                	xor    %ebx,%ebx
f0103b9c:	89 d8                	mov    %ebx,%eax
f0103b9e:	89 fa                	mov    %edi,%edx
f0103ba0:	83 c4 1c             	add    $0x1c,%esp
f0103ba3:	5b                   	pop    %ebx
f0103ba4:	5e                   	pop    %esi
f0103ba5:	5f                   	pop    %edi
f0103ba6:	5d                   	pop    %ebp
f0103ba7:	c3                   	ret    
f0103ba8:	90                   	nop
f0103ba9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103bb0:	89 d8                	mov    %ebx,%eax
f0103bb2:	f7 f7                	div    %edi
f0103bb4:	31 ff                	xor    %edi,%edi
f0103bb6:	89 c3                	mov    %eax,%ebx
f0103bb8:	89 d8                	mov    %ebx,%eax
f0103bba:	89 fa                	mov    %edi,%edx
f0103bbc:	83 c4 1c             	add    $0x1c,%esp
f0103bbf:	5b                   	pop    %ebx
f0103bc0:	5e                   	pop    %esi
f0103bc1:	5f                   	pop    %edi
f0103bc2:	5d                   	pop    %ebp
f0103bc3:	c3                   	ret    
f0103bc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103bc8:	39 ce                	cmp    %ecx,%esi
f0103bca:	72 0c                	jb     f0103bd8 <__udivdi3+0x118>
f0103bcc:	31 db                	xor    %ebx,%ebx
f0103bce:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103bd2:	0f 87 34 ff ff ff    	ja     f0103b0c <__udivdi3+0x4c>
f0103bd8:	bb 01 00 00 00       	mov    $0x1,%ebx
f0103bdd:	e9 2a ff ff ff       	jmp    f0103b0c <__udivdi3+0x4c>
f0103be2:	66 90                	xchg   %ax,%ax
f0103be4:	66 90                	xchg   %ax,%ax
f0103be6:	66 90                	xchg   %ax,%ax
f0103be8:	66 90                	xchg   %ax,%ax
f0103bea:	66 90                	xchg   %ax,%ax
f0103bec:	66 90                	xchg   %ax,%ax
f0103bee:	66 90                	xchg   %ax,%ax

f0103bf0 <__umoddi3>:
f0103bf0:	55                   	push   %ebp
f0103bf1:	57                   	push   %edi
f0103bf2:	56                   	push   %esi
f0103bf3:	53                   	push   %ebx
f0103bf4:	83 ec 1c             	sub    $0x1c,%esp
f0103bf7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103bfb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103bff:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103c03:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103c07:	85 d2                	test   %edx,%edx
f0103c09:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103c0d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c11:	89 f3                	mov    %esi,%ebx
f0103c13:	89 3c 24             	mov    %edi,(%esp)
f0103c16:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103c1a:	75 1c                	jne    f0103c38 <__umoddi3+0x48>
f0103c1c:	39 f7                	cmp    %esi,%edi
f0103c1e:	76 50                	jbe    f0103c70 <__umoddi3+0x80>
f0103c20:	89 c8                	mov    %ecx,%eax
f0103c22:	89 f2                	mov    %esi,%edx
f0103c24:	f7 f7                	div    %edi
f0103c26:	89 d0                	mov    %edx,%eax
f0103c28:	31 d2                	xor    %edx,%edx
f0103c2a:	83 c4 1c             	add    $0x1c,%esp
f0103c2d:	5b                   	pop    %ebx
f0103c2e:	5e                   	pop    %esi
f0103c2f:	5f                   	pop    %edi
f0103c30:	5d                   	pop    %ebp
f0103c31:	c3                   	ret    
f0103c32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103c38:	39 f2                	cmp    %esi,%edx
f0103c3a:	89 d0                	mov    %edx,%eax
f0103c3c:	77 52                	ja     f0103c90 <__umoddi3+0xa0>
f0103c3e:	0f bd ea             	bsr    %edx,%ebp
f0103c41:	83 f5 1f             	xor    $0x1f,%ebp
f0103c44:	75 5a                	jne    f0103ca0 <__umoddi3+0xb0>
f0103c46:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0103c4a:	0f 82 e0 00 00 00    	jb     f0103d30 <__umoddi3+0x140>
f0103c50:	39 0c 24             	cmp    %ecx,(%esp)
f0103c53:	0f 86 d7 00 00 00    	jbe    f0103d30 <__umoddi3+0x140>
f0103c59:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103c5d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103c61:	83 c4 1c             	add    $0x1c,%esp
f0103c64:	5b                   	pop    %ebx
f0103c65:	5e                   	pop    %esi
f0103c66:	5f                   	pop    %edi
f0103c67:	5d                   	pop    %ebp
f0103c68:	c3                   	ret    
f0103c69:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103c70:	85 ff                	test   %edi,%edi
f0103c72:	89 fd                	mov    %edi,%ebp
f0103c74:	75 0b                	jne    f0103c81 <__umoddi3+0x91>
f0103c76:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c7b:	31 d2                	xor    %edx,%edx
f0103c7d:	f7 f7                	div    %edi
f0103c7f:	89 c5                	mov    %eax,%ebp
f0103c81:	89 f0                	mov    %esi,%eax
f0103c83:	31 d2                	xor    %edx,%edx
f0103c85:	f7 f5                	div    %ebp
f0103c87:	89 c8                	mov    %ecx,%eax
f0103c89:	f7 f5                	div    %ebp
f0103c8b:	89 d0                	mov    %edx,%eax
f0103c8d:	eb 99                	jmp    f0103c28 <__umoddi3+0x38>
f0103c8f:	90                   	nop
f0103c90:	89 c8                	mov    %ecx,%eax
f0103c92:	89 f2                	mov    %esi,%edx
f0103c94:	83 c4 1c             	add    $0x1c,%esp
f0103c97:	5b                   	pop    %ebx
f0103c98:	5e                   	pop    %esi
f0103c99:	5f                   	pop    %edi
f0103c9a:	5d                   	pop    %ebp
f0103c9b:	c3                   	ret    
f0103c9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103ca0:	8b 34 24             	mov    (%esp),%esi
f0103ca3:	bf 20 00 00 00       	mov    $0x20,%edi
f0103ca8:	89 e9                	mov    %ebp,%ecx
f0103caa:	29 ef                	sub    %ebp,%edi
f0103cac:	d3 e0                	shl    %cl,%eax
f0103cae:	89 f9                	mov    %edi,%ecx
f0103cb0:	89 f2                	mov    %esi,%edx
f0103cb2:	d3 ea                	shr    %cl,%edx
f0103cb4:	89 e9                	mov    %ebp,%ecx
f0103cb6:	09 c2                	or     %eax,%edx
f0103cb8:	89 d8                	mov    %ebx,%eax
f0103cba:	89 14 24             	mov    %edx,(%esp)
f0103cbd:	89 f2                	mov    %esi,%edx
f0103cbf:	d3 e2                	shl    %cl,%edx
f0103cc1:	89 f9                	mov    %edi,%ecx
f0103cc3:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103cc7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103ccb:	d3 e8                	shr    %cl,%eax
f0103ccd:	89 e9                	mov    %ebp,%ecx
f0103ccf:	89 c6                	mov    %eax,%esi
f0103cd1:	d3 e3                	shl    %cl,%ebx
f0103cd3:	89 f9                	mov    %edi,%ecx
f0103cd5:	89 d0                	mov    %edx,%eax
f0103cd7:	d3 e8                	shr    %cl,%eax
f0103cd9:	89 e9                	mov    %ebp,%ecx
f0103cdb:	09 d8                	or     %ebx,%eax
f0103cdd:	89 d3                	mov    %edx,%ebx
f0103cdf:	89 f2                	mov    %esi,%edx
f0103ce1:	f7 34 24             	divl   (%esp)
f0103ce4:	89 d6                	mov    %edx,%esi
f0103ce6:	d3 e3                	shl    %cl,%ebx
f0103ce8:	f7 64 24 04          	mull   0x4(%esp)
f0103cec:	39 d6                	cmp    %edx,%esi
f0103cee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103cf2:	89 d1                	mov    %edx,%ecx
f0103cf4:	89 c3                	mov    %eax,%ebx
f0103cf6:	72 08                	jb     f0103d00 <__umoddi3+0x110>
f0103cf8:	75 11                	jne    f0103d0b <__umoddi3+0x11b>
f0103cfa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103cfe:	73 0b                	jae    f0103d0b <__umoddi3+0x11b>
f0103d00:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103d04:	1b 14 24             	sbb    (%esp),%edx
f0103d07:	89 d1                	mov    %edx,%ecx
f0103d09:	89 c3                	mov    %eax,%ebx
f0103d0b:	8b 54 24 08          	mov    0x8(%esp),%edx
f0103d0f:	29 da                	sub    %ebx,%edx
f0103d11:	19 ce                	sbb    %ecx,%esi
f0103d13:	89 f9                	mov    %edi,%ecx
f0103d15:	89 f0                	mov    %esi,%eax
f0103d17:	d3 e0                	shl    %cl,%eax
f0103d19:	89 e9                	mov    %ebp,%ecx
f0103d1b:	d3 ea                	shr    %cl,%edx
f0103d1d:	89 e9                	mov    %ebp,%ecx
f0103d1f:	d3 ee                	shr    %cl,%esi
f0103d21:	09 d0                	or     %edx,%eax
f0103d23:	89 f2                	mov    %esi,%edx
f0103d25:	83 c4 1c             	add    $0x1c,%esp
f0103d28:	5b                   	pop    %ebx
f0103d29:	5e                   	pop    %esi
f0103d2a:	5f                   	pop    %edi
f0103d2b:	5d                   	pop    %ebp
f0103d2c:	c3                   	ret    
f0103d2d:	8d 76 00             	lea    0x0(%esi),%esi
f0103d30:	29 f9                	sub    %edi,%ecx
f0103d32:	19 d6                	sbb    %edx,%esi
f0103d34:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103d38:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103d3c:	e9 18 ff ff ff       	jmp    f0103c59 <__umoddi3+0x69>
