
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 00 19 10 f0       	push   $0xf0101900
f0100050:	e8 4c 09 00 00       	call   f01009a1 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 0a 07 00 00       	call   f0100785 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 1c 19 10 f0       	push   $0xf010191c
f0100087:	e8 15 09 00 00       	call   f01009a1 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 40 29 11 f0       	mov    $0xf0112940,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 ab 13 00 00       	call   f010145c <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 9d 04 00 00       	call   f0100553 <cons_init>
	
	//unsigned int i = 0x00646c72;
    //cprintf("H%x Wo%s", 57616, &i);

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 37 19 10 f0       	push   $0xf0101937
f01000c3:	e8 d9 08 00 00       	call   f01009a1 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 53 07 00 00       	call   f0100834 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 44 29 11 f0 00 	cmpl   $0x0,0xf0112944
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 44 29 11 f0    	mov    %esi,0xf0112944

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 52 19 10 f0       	push   $0xf0101952
f0100110:	e8 8c 08 00 00       	call   f01009a1 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 5c 08 00 00       	call   f010097b <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 8e 19 10 f0 	movl   $0xf010198e,(%esp)
f0100126:	e8 76 08 00 00       	call   f01009a1 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 fc 06 00 00       	call   f0100834 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 6a 19 10 f0       	push   $0xf010196a
f0100152:	e8 4a 08 00 00       	call   f01009a1 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 18 08 00 00       	call   f010097b <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 8e 19 10 f0 	movl   $0xf010198e,(%esp)
f010016a:	e8 32 08 00 00       	call   f01009a1 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f8 00 00 00    	je     f01002df <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001e7:	a8 20                	test   $0x20,%al
f01001e9:	0f 85 f6 00 00 00    	jne    f01002e5 <kbd_proc_data+0x10c>
f01001ef:	ba 60 00 00 00       	mov    $0x60,%edx
f01001f4:	ec                   	in     (%dx),%al
f01001f5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001f7:	3c e0                	cmp    $0xe0,%al
f01001f9:	75 0d                	jne    f0100208 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001fb:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100202:	b8 00 00 00 00       	mov    $0x0,%eax
f0100207:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100208:	55                   	push   %ebp
f0100209:	89 e5                	mov    %esp,%ebp
f010020b:	53                   	push   %ebx
f010020c:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010020f:	84 c0                	test   %al,%al
f0100211:	79 36                	jns    f0100249 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100213:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100219:	89 cb                	mov    %ecx,%ebx
f010021b:	83 e3 40             	and    $0x40,%ebx
f010021e:	83 e0 7f             	and    $0x7f,%eax
f0100221:	85 db                	test   %ebx,%ebx
f0100223:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100226:	0f b6 d2             	movzbl %dl,%edx
f0100229:	0f b6 82 e0 1a 10 f0 	movzbl -0xfefe520(%edx),%eax
f0100230:	83 c8 40             	or     $0x40,%eax
f0100233:	0f b6 c0             	movzbl %al,%eax
f0100236:	f7 d0                	not    %eax
f0100238:	21 c8                	and    %ecx,%eax
f010023a:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f010023f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100244:	e9 a4 00 00 00       	jmp    f01002ed <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100249:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010024f:	f6 c1 40             	test   $0x40,%cl
f0100252:	74 0e                	je     f0100262 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100254:	83 c8 80             	or     $0xffffff80,%eax
f0100257:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100259:	83 e1 bf             	and    $0xffffffbf,%ecx
f010025c:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100262:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 82 e0 1a 10 f0 	movzbl -0xfefe520(%edx),%eax
f010026c:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100272:	0f b6 8a e0 19 10 f0 	movzbl -0xfefe620(%edx),%ecx
f0100279:	31 c8                	xor    %ecx,%eax
f010027b:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100280:	89 c1                	mov    %eax,%ecx
f0100282:	83 e1 03             	and    $0x3,%ecx
f0100285:	8b 0c 8d c0 19 10 f0 	mov    -0xfefe640(,%ecx,4),%ecx
f010028c:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100290:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100293:	a8 08                	test   $0x8,%al
f0100295:	74 1b                	je     f01002b2 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100297:	89 da                	mov    %ebx,%edx
f0100299:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010029c:	83 f9 19             	cmp    $0x19,%ecx
f010029f:	77 05                	ja     f01002a6 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01002a1:	83 eb 20             	sub    $0x20,%ebx
f01002a4:	eb 0c                	jmp    f01002b2 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01002a6:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a9:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002ac:	83 fa 19             	cmp    $0x19,%edx
f01002af:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002b2:	f7 d0                	not    %eax
f01002b4:	a8 06                	test   $0x6,%al
f01002b6:	75 33                	jne    f01002eb <kbd_proc_data+0x112>
f01002b8:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002be:	75 2b                	jne    f01002eb <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01002c0:	83 ec 0c             	sub    $0xc,%esp
f01002c3:	68 84 19 10 f0       	push   $0xf0101984
f01002c8:	e8 d4 06 00 00       	call   f01009a1 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002cd:	ba 92 00 00 00       	mov    $0x92,%edx
f01002d2:	b8 03 00 00 00       	mov    $0x3,%eax
f01002d7:	ee                   	out    %al,(%dx)
f01002d8:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
f01002dd:	eb 0e                	jmp    f01002ed <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002e4:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ea:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002eb:	89 d8                	mov    %ebx,%eax
}
f01002ed:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002f0:	c9                   	leave  
f01002f1:	c3                   	ret    

f01002f2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002f2:	55                   	push   %ebp
f01002f3:	89 e5                	mov    %esp,%ebp
f01002f5:	57                   	push   %edi
f01002f6:	56                   	push   %esi
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 1c             	sub    $0x1c,%esp
f01002fb:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002fd:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100302:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100307:	b9 84 00 00 00       	mov    $0x84,%ecx
f010030c:	eb 09                	jmp    f0100317 <cons_putc+0x25>
f010030e:	89 ca                	mov    %ecx,%edx
f0100310:	ec                   	in     (%dx),%al
f0100311:	ec                   	in     (%dx),%al
f0100312:	ec                   	in     (%dx),%al
f0100313:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100314:	83 c3 01             	add    $0x1,%ebx
f0100317:	89 f2                	mov    %esi,%edx
f0100319:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 08                	jne    f0100326 <cons_putc+0x34>
f010031e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100324:	7e e8                	jle    f010030e <cons_putc+0x1c>
f0100326:	89 f8                	mov    %edi,%eax
f0100328:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010032b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100330:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100331:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100336:	be 79 03 00 00       	mov    $0x379,%esi
f010033b:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100340:	eb 09                	jmp    f010034b <cons_putc+0x59>
f0100342:	89 ca                	mov    %ecx,%edx
f0100344:	ec                   	in     (%dx),%al
f0100345:	ec                   	in     (%dx),%al
f0100346:	ec                   	in     (%dx),%al
f0100347:	ec                   	in     (%dx),%al
f0100348:	83 c3 01             	add    $0x1,%ebx
f010034b:	89 f2                	mov    %esi,%edx
f010034d:	ec                   	in     (%dx),%al
f010034e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100354:	7f 04                	jg     f010035a <cons_putc+0x68>
f0100356:	84 c0                	test   %al,%al
f0100358:	79 e8                	jns    f0100342 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010035a:	ba 78 03 00 00       	mov    $0x378,%edx
f010035f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100363:	ee                   	out    %al,(%dx)
f0100364:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100369:	b8 0d 00 00 00       	mov    $0xd,%eax
f010036e:	ee                   	out    %al,(%dx)
f010036f:	b8 08 00 00 00       	mov    $0x8,%eax
f0100374:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100375:	89 fa                	mov    %edi,%edx
f0100377:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010037d:	89 f8                	mov    %edi,%eax
f010037f:	80 cc 07             	or     $0x7,%ah
f0100382:	85 d2                	test   %edx,%edx
f0100384:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100387:	89 f8                	mov    %edi,%eax
f0100389:	0f b6 c0             	movzbl %al,%eax
f010038c:	83 f8 09             	cmp    $0x9,%eax
f010038f:	74 74                	je     f0100405 <cons_putc+0x113>
f0100391:	83 f8 09             	cmp    $0x9,%eax
f0100394:	7f 0a                	jg     f01003a0 <cons_putc+0xae>
f0100396:	83 f8 08             	cmp    $0x8,%eax
f0100399:	74 14                	je     f01003af <cons_putc+0xbd>
f010039b:	e9 99 00 00 00       	jmp    f0100439 <cons_putc+0x147>
f01003a0:	83 f8 0a             	cmp    $0xa,%eax
f01003a3:	74 3a                	je     f01003df <cons_putc+0xed>
f01003a5:	83 f8 0d             	cmp    $0xd,%eax
f01003a8:	74 3d                	je     f01003e7 <cons_putc+0xf5>
f01003aa:	e9 8a 00 00 00       	jmp    f0100439 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003af:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003b6:	66 85 c0             	test   %ax,%ax
f01003b9:	0f 84 e6 00 00 00    	je     f01004a5 <cons_putc+0x1b3>
			crt_pos--;
f01003bf:	83 e8 01             	sub    $0x1,%eax
f01003c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003c8:	0f b7 c0             	movzwl %ax,%eax
f01003cb:	66 81 e7 00 ff       	and    $0xff00,%di
f01003d0:	83 cf 20             	or     $0x20,%edi
f01003d3:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003d9:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003dd:	eb 78                	jmp    f0100457 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003df:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003e6:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003e7:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003ee:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003f4:	c1 e8 16             	shr    $0x16,%eax
f01003f7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003fa:	c1 e0 04             	shl    $0x4,%eax
f01003fd:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100403:	eb 52                	jmp    f0100457 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f0100405:	b8 20 00 00 00       	mov    $0x20,%eax
f010040a:	e8 e3 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010040f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100414:	e8 d9 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100419:	b8 20 00 00 00       	mov    $0x20,%eax
f010041e:	e8 cf fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100423:	b8 20 00 00 00       	mov    $0x20,%eax
f0100428:	e8 c5 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010042d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100432:	e8 bb fe ff ff       	call   f01002f2 <cons_putc>
f0100437:	eb 1e                	jmp    f0100457 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100439:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100440:	8d 50 01             	lea    0x1(%eax),%edx
f0100443:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010044a:	0f b7 c0             	movzwl %ax,%eax
f010044d:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100453:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100457:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010045e:	cf 07 
f0100460:	76 43                	jbe    f01004a5 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100462:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100467:	83 ec 04             	sub    $0x4,%esp
f010046a:	68 00 0f 00 00       	push   $0xf00
f010046f:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100475:	52                   	push   %edx
f0100476:	50                   	push   %eax
f0100477:	e8 2d 10 00 00       	call   f01014a9 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010047c:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100482:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100488:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010048e:	83 c4 10             	add    $0x10,%esp
f0100491:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100496:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100499:	39 d0                	cmp    %edx,%eax
f010049b:	75 f4                	jne    f0100491 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010049d:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004a4:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004a5:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004ab:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004b0:	89 ca                	mov    %ecx,%edx
f01004b2:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004b3:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ba:	8d 71 01             	lea    0x1(%ecx),%esi
f01004bd:	89 d8                	mov    %ebx,%eax
f01004bf:	66 c1 e8 08          	shr    $0x8,%ax
f01004c3:	89 f2                	mov    %esi,%edx
f01004c5:	ee                   	out    %al,(%dx)
f01004c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004cb:	89 ca                	mov    %ecx,%edx
f01004cd:	ee                   	out    %al,(%dx)
f01004ce:	89 d8                	mov    %ebx,%eax
f01004d0:	89 f2                	mov    %esi,%edx
f01004d2:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004d6:	5b                   	pop    %ebx
f01004d7:	5e                   	pop    %esi
f01004d8:	5f                   	pop    %edi
f01004d9:	5d                   	pop    %ebp
f01004da:	c3                   	ret    

f01004db <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004db:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004e2:	74 11                	je     f01004f5 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004e4:	55                   	push   %ebp
f01004e5:	89 e5                	mov    %esp,%ebp
f01004e7:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004ea:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004ef:	e8 a2 fc ff ff       	call   f0100196 <cons_intr>
}
f01004f4:	c9                   	leave  
f01004f5:	f3 c3                	repz ret 

f01004f7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004f7:	55                   	push   %ebp
f01004f8:	89 e5                	mov    %esp,%ebp
f01004fa:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004fd:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f0100502:	e8 8f fc ff ff       	call   f0100196 <cons_intr>
}
f0100507:	c9                   	leave  
f0100508:	c3                   	ret    

f0100509 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100509:	55                   	push   %ebp
f010050a:	89 e5                	mov    %esp,%ebp
f010050c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010050f:	e8 c7 ff ff ff       	call   f01004db <serial_intr>
	kbd_intr();
f0100514:	e8 de ff ff ff       	call   f01004f7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100519:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010051e:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100524:	74 26                	je     f010054c <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100526:	8d 50 01             	lea    0x1(%eax),%edx
f0100529:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010052f:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100536:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100538:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010053e:	75 11                	jne    f0100551 <cons_getc+0x48>
			cons.rpos = 0;
f0100540:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100547:	00 00 00 
f010054a:	eb 05                	jmp    f0100551 <cons_getc+0x48>
		return c;
	}
	return 0;
f010054c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100551:	c9                   	leave  
f0100552:	c3                   	ret    

f0100553 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100553:	55                   	push   %ebp
f0100554:	89 e5                	mov    %esp,%ebp
f0100556:	57                   	push   %edi
f0100557:	56                   	push   %esi
f0100558:	53                   	push   %ebx
f0100559:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010055c:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100563:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010056a:	5a a5 
	if (*cp != 0xA55A) {
f010056c:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100573:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100577:	74 11                	je     f010058a <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100579:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100580:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100583:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100588:	eb 16                	jmp    f01005a0 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010058a:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100591:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f0100598:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010059b:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a0:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f01005a6:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ab:	89 fa                	mov    %edi,%edx
f01005ad:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ae:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b1:	89 da                	mov    %ebx,%edx
f01005b3:	ec                   	in     (%dx),%al
f01005b4:	0f b6 c8             	movzbl %al,%ecx
f01005b7:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ba:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005bf:	89 fa                	mov    %edi,%edx
f01005c1:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c2:	89 da                	mov    %ebx,%edx
f01005c4:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005c5:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005cb:	0f b6 c0             	movzbl %al,%eax
f01005ce:	09 c8                	or     %ecx,%eax
f01005d0:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005db:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e0:	89 f2                	mov    %esi,%edx
f01005e2:	ee                   	out    %al,(%dx)
f01005e3:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005e8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005ed:	ee                   	out    %al,(%dx)
f01005ee:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005f3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005f8:	89 da                	mov    %ebx,%edx
f01005fa:	ee                   	out    %al,(%dx)
f01005fb:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100600:	b8 00 00 00 00       	mov    $0x0,%eax
f0100605:	ee                   	out    %al,(%dx)
f0100606:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010060b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100610:	ee                   	out    %al,(%dx)
f0100611:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100616:	b8 00 00 00 00       	mov    $0x0,%eax
f010061b:	ee                   	out    %al,(%dx)
f010061c:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100621:	b8 01 00 00 00       	mov    $0x1,%eax
f0100626:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100627:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010062f:	3c ff                	cmp    $0xff,%al
f0100631:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f0100638:	89 f2                	mov    %esi,%edx
f010063a:	ec                   	in     (%dx),%al
f010063b:	89 da                	mov    %ebx,%edx
f010063d:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010063e:	80 f9 ff             	cmp    $0xff,%cl
f0100641:	75 10                	jne    f0100653 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100643:	83 ec 0c             	sub    $0xc,%esp
f0100646:	68 90 19 10 f0       	push   $0xf0101990
f010064b:	e8 51 03 00 00       	call   f01009a1 <cprintf>
f0100650:	83 c4 10             	add    $0x10,%esp
}
f0100653:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100656:	5b                   	pop    %ebx
f0100657:	5e                   	pop    %esi
f0100658:	5f                   	pop    %edi
f0100659:	5d                   	pop    %ebp
f010065a:	c3                   	ret    

f010065b <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010065b:	55                   	push   %ebp
f010065c:	89 e5                	mov    %esp,%ebp
f010065e:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100661:	8b 45 08             	mov    0x8(%ebp),%eax
f0100664:	e8 89 fc ff ff       	call   f01002f2 <cons_putc>
}
f0100669:	c9                   	leave  
f010066a:	c3                   	ret    

f010066b <getchar>:

int
getchar(void)
{
f010066b:	55                   	push   %ebp
f010066c:	89 e5                	mov    %esp,%ebp
f010066e:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100671:	e8 93 fe ff ff       	call   f0100509 <cons_getc>
f0100676:	85 c0                	test   %eax,%eax
f0100678:	74 f7                	je     f0100671 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010067a:	c9                   	leave  
f010067b:	c3                   	ret    

f010067c <iscons>:

int
iscons(int fdnum)
{
f010067c:	55                   	push   %ebp
f010067d:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010067f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100684:	5d                   	pop    %ebp
f0100685:	c3                   	ret    

f0100686 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100686:	55                   	push   %ebp
f0100687:	89 e5                	mov    %esp,%ebp
f0100689:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010068c:	68 e0 1b 10 f0       	push   $0xf0101be0
f0100691:	68 fe 1b 10 f0       	push   $0xf0101bfe
f0100696:	68 03 1c 10 f0       	push   $0xf0101c03
f010069b:	e8 01 03 00 00       	call   f01009a1 <cprintf>
f01006a0:	83 c4 0c             	add    $0xc,%esp
f01006a3:	68 b0 1c 10 f0       	push   $0xf0101cb0
f01006a8:	68 0c 1c 10 f0       	push   $0xf0101c0c
f01006ad:	68 03 1c 10 f0       	push   $0xf0101c03
f01006b2:	e8 ea 02 00 00       	call   f01009a1 <cprintf>
f01006b7:	83 c4 0c             	add    $0xc,%esp
f01006ba:	68 15 1c 10 f0       	push   $0xf0101c15
f01006bf:	68 23 1c 10 f0       	push   $0xf0101c23
f01006c4:	68 03 1c 10 f0       	push   $0xf0101c03
f01006c9:	e8 d3 02 00 00       	call   f01009a1 <cprintf>
	return 0;
}
f01006ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d3:	c9                   	leave  
f01006d4:	c3                   	ret    

f01006d5 <mon_kerninfo>:


int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006d5:	55                   	push   %ebp
f01006d6:	89 e5                	mov    %esp,%ebp
f01006d8:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006db:	68 2d 1c 10 f0       	push   $0xf0101c2d
f01006e0:	e8 bc 02 00 00       	call   f01009a1 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006e5:	83 c4 08             	add    $0x8,%esp
f01006e8:	68 0c 00 10 00       	push   $0x10000c
f01006ed:	68 d8 1c 10 f0       	push   $0xf0101cd8
f01006f2:	e8 aa 02 00 00       	call   f01009a1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006f7:	83 c4 0c             	add    $0xc,%esp
f01006fa:	68 0c 00 10 00       	push   $0x10000c
f01006ff:	68 0c 00 10 f0       	push   $0xf010000c
f0100704:	68 00 1d 10 f0       	push   $0xf0101d00
f0100709:	e8 93 02 00 00       	call   f01009a1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010070e:	83 c4 0c             	add    $0xc,%esp
f0100711:	68 e1 18 10 00       	push   $0x1018e1
f0100716:	68 e1 18 10 f0       	push   $0xf01018e1
f010071b:	68 24 1d 10 f0       	push   $0xf0101d24
f0100720:	e8 7c 02 00 00       	call   f01009a1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100725:	83 c4 0c             	add    $0xc,%esp
f0100728:	68 00 23 11 00       	push   $0x112300
f010072d:	68 00 23 11 f0       	push   $0xf0112300
f0100732:	68 48 1d 10 f0       	push   $0xf0101d48
f0100737:	e8 65 02 00 00       	call   f01009a1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010073c:	83 c4 0c             	add    $0xc,%esp
f010073f:	68 40 29 11 00       	push   $0x112940
f0100744:	68 40 29 11 f0       	push   $0xf0112940
f0100749:	68 6c 1d 10 f0       	push   $0xf0101d6c
f010074e:	e8 4e 02 00 00       	call   f01009a1 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100753:	b8 3f 2d 11 f0       	mov    $0xf0112d3f,%eax
f0100758:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010075d:	83 c4 08             	add    $0x8,%esp
f0100760:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100765:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010076b:	85 c0                	test   %eax,%eax
f010076d:	0f 48 c2             	cmovs  %edx,%eax
f0100770:	c1 f8 0a             	sar    $0xa,%eax
f0100773:	50                   	push   %eax
f0100774:	68 90 1d 10 f0       	push   $0xf0101d90
f0100779:	e8 23 02 00 00       	call   f01009a1 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010077e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100783:	c9                   	leave  
f0100784:	c3                   	ret    

f0100785 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100785:	55                   	push   %ebp
f0100786:	89 e5                	mov    %esp,%ebp
f0100788:	57                   	push   %edi
f0100789:	56                   	push   %esi
f010078a:	53                   	push   %ebx
f010078b:	83 ec 38             	sub    $0x38,%esp
	// Your code here.
	cprintf("Stack backtrace:\n");
f010078e:	68 46 1c 10 f0       	push   $0xf0101c46
f0100793:	e8 09 02 00 00       	call   f01009a1 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100798:	89 ee                	mov    %ebp,%esi
	int* ebp = ((int*)read_ebp());
	while (ebp != 0)
f010079a:	83 c4 10             	add    $0x10,%esp
	{
		int eip = *(ebp+1);
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",ebp+1,eip,*(ebp+2),*(ebp+3),*(ebp+4),*(ebp+5),*(ebp+6));
		struct Eipdebuginfo info;
		int tmp = debuginfo_eip(eip, &info);
f010079d:	8d 7d d0             	lea    -0x30(%ebp),%edi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	int* ebp = ((int*)read_ebp());
	while (ebp != 0)
f01007a0:	eb 7d                	jmp    f010081f <mon_backtrace+0x9a>
	{
		int eip = *(ebp+1);
f01007a2:	8b 5e 04             	mov    0x4(%esi),%ebx
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",ebp+1,eip,*(ebp+2),*(ebp+3),*(ebp+4),*(ebp+5),*(ebp+6));
f01007a5:	ff 76 18             	pushl  0x18(%esi)
f01007a8:	ff 76 14             	pushl  0x14(%esi)
f01007ab:	ff 76 10             	pushl  0x10(%esi)
f01007ae:	ff 76 0c             	pushl  0xc(%esi)
f01007b1:	ff 76 08             	pushl  0x8(%esi)
f01007b4:	53                   	push   %ebx
f01007b5:	8d 46 04             	lea    0x4(%esi),%eax
f01007b8:	50                   	push   %eax
f01007b9:	68 bc 1d 10 f0       	push   $0xf0101dbc
f01007be:	e8 de 01 00 00       	call   f01009a1 <cprintf>
		struct Eipdebuginfo info;
		int tmp = debuginfo_eip(eip, &info);
f01007c3:	83 c4 18             	add    $0x18,%esp
f01007c6:	57                   	push   %edi
f01007c7:	53                   	push   %ebx
f01007c8:	e8 de 02 00 00       	call   f0100aab <debuginfo_eip>
		cprintf("         %s:%d: ",info.eip_file,info.eip_line);
f01007cd:	83 c4 0c             	add    $0xc,%esp
f01007d0:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007d3:	ff 75 d0             	pushl  -0x30(%ebp)
f01007d6:	68 58 1c 10 f0       	push   $0xf0101c58
f01007db:	e8 c1 01 00 00       	call   f01009a1 <cprintf>
		for (int i=0;i<info.eip_fn_namelen;i++)
f01007e0:	83 c4 10             	add    $0x10,%esp
f01007e3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01007e8:	eb 1b                	jmp    f0100805 <mon_backtrace+0x80>
			cprintf("%c",info.eip_fn_name[i]);
f01007ea:	83 ec 08             	sub    $0x8,%esp
f01007ed:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007f0:	0f be 04 18          	movsbl (%eax,%ebx,1),%eax
f01007f4:	50                   	push   %eax
f01007f5:	68 69 1c 10 f0       	push   $0xf0101c69
f01007fa:	e8 a2 01 00 00       	call   f01009a1 <cprintf>
		int eip = *(ebp+1);
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",ebp+1,eip,*(ebp+2),*(ebp+3),*(ebp+4),*(ebp+5),*(ebp+6));
		struct Eipdebuginfo info;
		int tmp = debuginfo_eip(eip, &info);
		cprintf("         %s:%d: ",info.eip_file,info.eip_line);
		for (int i=0;i<info.eip_fn_namelen;i++)
f01007ff:	83 c3 01             	add    $0x1,%ebx
f0100802:	83 c4 10             	add    $0x10,%esp
f0100805:	3b 5d dc             	cmp    -0x24(%ebp),%ebx
f0100808:	7c e0                	jl     f01007ea <mon_backtrace+0x65>
			cprintf("%c",info.eip_fn_name[i]);
		cprintf("+%d\n",info.eip_fn_narg);
f010080a:	83 ec 08             	sub    $0x8,%esp
f010080d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100810:	68 6c 1c 10 f0       	push   $0xf0101c6c
f0100815:	e8 87 01 00 00       	call   f01009a1 <cprintf>
		ebp = (int*)(*(ebp));
f010081a:	8b 36                	mov    (%esi),%esi
f010081c:	83 c4 10             	add    $0x10,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	int* ebp = ((int*)read_ebp());
	while (ebp != 0)
f010081f:	85 f6                	test   %esi,%esi
f0100821:	0f 85 7b ff ff ff    	jne    f01007a2 <mon_backtrace+0x1d>
		cprintf("+%d\n",info.eip_fn_narg);
		ebp = (int*)(*(ebp));
		
	}
	return 0;
}
f0100827:	b8 00 00 00 00       	mov    $0x0,%eax
f010082c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010082f:	5b                   	pop    %ebx
f0100830:	5e                   	pop    %esi
f0100831:	5f                   	pop    %edi
f0100832:	5d                   	pop    %ebp
f0100833:	c3                   	ret    

f0100834 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100834:	55                   	push   %ebp
f0100835:	89 e5                	mov    %esp,%ebp
f0100837:	57                   	push   %edi
f0100838:	56                   	push   %esi
f0100839:	53                   	push   %ebx
f010083a:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010083d:	68 f4 1d 10 f0       	push   $0xf0101df4
f0100842:	e8 5a 01 00 00       	call   f01009a1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100847:	c7 04 24 18 1e 10 f0 	movl   $0xf0101e18,(%esp)
f010084e:	e8 4e 01 00 00       	call   f01009a1 <cprintf>
f0100853:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100856:	83 ec 0c             	sub    $0xc,%esp
f0100859:	68 71 1c 10 f0       	push   $0xf0101c71
f010085e:	e8 a2 09 00 00       	call   f0101205 <readline>
f0100863:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100865:	83 c4 10             	add    $0x10,%esp
f0100868:	85 c0                	test   %eax,%eax
f010086a:	74 ea                	je     f0100856 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010086c:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100873:	be 00 00 00 00       	mov    $0x0,%esi
f0100878:	eb 0a                	jmp    f0100884 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010087a:	c6 03 00             	movb   $0x0,(%ebx)
f010087d:	89 f7                	mov    %esi,%edi
f010087f:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100882:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100884:	0f b6 03             	movzbl (%ebx),%eax
f0100887:	84 c0                	test   %al,%al
f0100889:	74 63                	je     f01008ee <monitor+0xba>
f010088b:	83 ec 08             	sub    $0x8,%esp
f010088e:	0f be c0             	movsbl %al,%eax
f0100891:	50                   	push   %eax
f0100892:	68 75 1c 10 f0       	push   $0xf0101c75
f0100897:	e8 83 0b 00 00       	call   f010141f <strchr>
f010089c:	83 c4 10             	add    $0x10,%esp
f010089f:	85 c0                	test   %eax,%eax
f01008a1:	75 d7                	jne    f010087a <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01008a3:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008a6:	74 46                	je     f01008ee <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008a8:	83 fe 0f             	cmp    $0xf,%esi
f01008ab:	75 14                	jne    f01008c1 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008ad:	83 ec 08             	sub    $0x8,%esp
f01008b0:	6a 10                	push   $0x10
f01008b2:	68 7a 1c 10 f0       	push   $0xf0101c7a
f01008b7:	e8 e5 00 00 00       	call   f01009a1 <cprintf>
f01008bc:	83 c4 10             	add    $0x10,%esp
f01008bf:	eb 95                	jmp    f0100856 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01008c1:	8d 7e 01             	lea    0x1(%esi),%edi
f01008c4:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008c8:	eb 03                	jmp    f01008cd <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008ca:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008cd:	0f b6 03             	movzbl (%ebx),%eax
f01008d0:	84 c0                	test   %al,%al
f01008d2:	74 ae                	je     f0100882 <monitor+0x4e>
f01008d4:	83 ec 08             	sub    $0x8,%esp
f01008d7:	0f be c0             	movsbl %al,%eax
f01008da:	50                   	push   %eax
f01008db:	68 75 1c 10 f0       	push   $0xf0101c75
f01008e0:	e8 3a 0b 00 00       	call   f010141f <strchr>
f01008e5:	83 c4 10             	add    $0x10,%esp
f01008e8:	85 c0                	test   %eax,%eax
f01008ea:	74 de                	je     f01008ca <monitor+0x96>
f01008ec:	eb 94                	jmp    f0100882 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008ee:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008f5:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008f6:	85 f6                	test   %esi,%esi
f01008f8:	0f 84 58 ff ff ff    	je     f0100856 <monitor+0x22>
f01008fe:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100903:	83 ec 08             	sub    $0x8,%esp
f0100906:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100909:	ff 34 85 40 1e 10 f0 	pushl  -0xfefe1c0(,%eax,4)
f0100910:	ff 75 a8             	pushl  -0x58(%ebp)
f0100913:	e8 a9 0a 00 00       	call   f01013c1 <strcmp>
f0100918:	83 c4 10             	add    $0x10,%esp
f010091b:	85 c0                	test   %eax,%eax
f010091d:	75 21                	jne    f0100940 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f010091f:	83 ec 04             	sub    $0x4,%esp
f0100922:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100925:	ff 75 08             	pushl  0x8(%ebp)
f0100928:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010092b:	52                   	push   %edx
f010092c:	56                   	push   %esi
f010092d:	ff 14 85 48 1e 10 f0 	call   *-0xfefe1b8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100934:	83 c4 10             	add    $0x10,%esp
f0100937:	85 c0                	test   %eax,%eax
f0100939:	78 25                	js     f0100960 <monitor+0x12c>
f010093b:	e9 16 ff ff ff       	jmp    f0100856 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100940:	83 c3 01             	add    $0x1,%ebx
f0100943:	83 fb 03             	cmp    $0x3,%ebx
f0100946:	75 bb                	jne    f0100903 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100948:	83 ec 08             	sub    $0x8,%esp
f010094b:	ff 75 a8             	pushl  -0x58(%ebp)
f010094e:	68 97 1c 10 f0       	push   $0xf0101c97
f0100953:	e8 49 00 00 00       	call   f01009a1 <cprintf>
f0100958:	83 c4 10             	add    $0x10,%esp
f010095b:	e9 f6 fe ff ff       	jmp    f0100856 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100960:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100963:	5b                   	pop    %ebx
f0100964:	5e                   	pop    %esi
f0100965:	5f                   	pop    %edi
f0100966:	5d                   	pop    %ebp
f0100967:	c3                   	ret    

f0100968 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100968:	55                   	push   %ebp
f0100969:	89 e5                	mov    %esp,%ebp
f010096b:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010096e:	ff 75 08             	pushl  0x8(%ebp)
f0100971:	e8 e5 fc ff ff       	call   f010065b <cputchar>
	*cnt++;
}
f0100976:	83 c4 10             	add    $0x10,%esp
f0100979:	c9                   	leave  
f010097a:	c3                   	ret    

f010097b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010097b:	55                   	push   %ebp
f010097c:	89 e5                	mov    %esp,%ebp
f010097e:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100981:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100988:	ff 75 0c             	pushl  0xc(%ebp)
f010098b:	ff 75 08             	pushl  0x8(%ebp)
f010098e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100991:	50                   	push   %eax
f0100992:	68 68 09 10 f0       	push   $0xf0100968
f0100997:	e8 54 04 00 00       	call   f0100df0 <vprintfmt>
	return cnt;
}
f010099c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010099f:	c9                   	leave  
f01009a0:	c3                   	ret    

f01009a1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009a1:	55                   	push   %ebp
f01009a2:	89 e5                	mov    %esp,%ebp
f01009a4:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009a7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009aa:	50                   	push   %eax
f01009ab:	ff 75 08             	pushl  0x8(%ebp)
f01009ae:	e8 c8 ff ff ff       	call   f010097b <vcprintf>
	va_end(ap);

	return cnt;
}
f01009b3:	c9                   	leave  
f01009b4:	c3                   	ret    

f01009b5 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009b5:	55                   	push   %ebp
f01009b6:	89 e5                	mov    %esp,%ebp
f01009b8:	57                   	push   %edi
f01009b9:	56                   	push   %esi
f01009ba:	53                   	push   %ebx
f01009bb:	83 ec 14             	sub    $0x14,%esp
f01009be:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009c1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01009c4:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009c7:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009ca:	8b 1a                	mov    (%edx),%ebx
f01009cc:	8b 01                	mov    (%ecx),%eax
f01009ce:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009d1:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009d8:	eb 7f                	jmp    f0100a59 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01009da:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009dd:	01 d8                	add    %ebx,%eax
f01009df:	89 c6                	mov    %eax,%esi
f01009e1:	c1 ee 1f             	shr    $0x1f,%esi
f01009e4:	01 c6                	add    %eax,%esi
f01009e6:	d1 fe                	sar    %esi
f01009e8:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009eb:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009ee:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009f1:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009f3:	eb 03                	jmp    f01009f8 <stab_binsearch+0x43>
			m--;
f01009f5:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009f8:	39 c3                	cmp    %eax,%ebx
f01009fa:	7f 0d                	jg     f0100a09 <stab_binsearch+0x54>
f01009fc:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100a00:	83 ea 0c             	sub    $0xc,%edx
f0100a03:	39 f9                	cmp    %edi,%ecx
f0100a05:	75 ee                	jne    f01009f5 <stab_binsearch+0x40>
f0100a07:	eb 05                	jmp    f0100a0e <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a09:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a0c:	eb 4b                	jmp    f0100a59 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a0e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a11:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a14:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a18:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a1b:	76 11                	jbe    f0100a2e <stab_binsearch+0x79>
			*region_left = m;
f0100a1d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a20:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a22:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a25:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a2c:	eb 2b                	jmp    f0100a59 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a2e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a31:	73 14                	jae    f0100a47 <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a33:	83 e8 01             	sub    $0x1,%eax
f0100a36:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a39:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a3c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a3e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a45:	eb 12                	jmp    f0100a59 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a47:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a4a:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a4c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a50:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a52:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a59:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a5c:	0f 8e 78 ff ff ff    	jle    f01009da <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a62:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a66:	75 0f                	jne    f0100a77 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a68:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a6b:	8b 00                	mov    (%eax),%eax
f0100a6d:	83 e8 01             	sub    $0x1,%eax
f0100a70:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a73:	89 06                	mov    %eax,(%esi)
f0100a75:	eb 2c                	jmp    f0100aa3 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a77:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a7a:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a7c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a7f:	8b 0e                	mov    (%esi),%ecx
f0100a81:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a84:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a87:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a8a:	eb 03                	jmp    f0100a8f <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a8c:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a8f:	39 c8                	cmp    %ecx,%eax
f0100a91:	7e 0b                	jle    f0100a9e <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a93:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a97:	83 ea 0c             	sub    $0xc,%edx
f0100a9a:	39 df                	cmp    %ebx,%edi
f0100a9c:	75 ee                	jne    f0100a8c <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a9e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100aa1:	89 06                	mov    %eax,(%esi)
	}
}
f0100aa3:	83 c4 14             	add    $0x14,%esp
f0100aa6:	5b                   	pop    %ebx
f0100aa7:	5e                   	pop    %esi
f0100aa8:	5f                   	pop    %edi
f0100aa9:	5d                   	pop    %ebp
f0100aaa:	c3                   	ret    

f0100aab <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100aab:	55                   	push   %ebp
f0100aac:	89 e5                	mov    %esp,%ebp
f0100aae:	57                   	push   %edi
f0100aaf:	56                   	push   %esi
f0100ab0:	53                   	push   %ebx
f0100ab1:	83 ec 3c             	sub    $0x3c,%esp
f0100ab4:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ab7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100aba:	c7 03 64 1e 10 f0    	movl   $0xf0101e64,(%ebx)
	info->eip_line = 0;
f0100ac0:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ac7:	c7 43 08 64 1e 10 f0 	movl   $0xf0101e64,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ace:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ad5:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ad8:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100adf:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ae5:	76 11                	jbe    f0100af8 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ae7:	b8 fe 73 10 f0       	mov    $0xf01073fe,%eax
f0100aec:	3d d5 5a 10 f0       	cmp    $0xf0105ad5,%eax
f0100af1:	77 19                	ja     f0100b0c <debuginfo_eip+0x61>
f0100af3:	e9 ac 01 00 00       	jmp    f0100ca4 <debuginfo_eip+0x1f9>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100af8:	83 ec 04             	sub    $0x4,%esp
f0100afb:	68 6e 1e 10 f0       	push   $0xf0101e6e
f0100b00:	6a 7f                	push   $0x7f
f0100b02:	68 7b 1e 10 f0       	push   $0xf0101e7b
f0100b07:	e8 da f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b0c:	80 3d fd 73 10 f0 00 	cmpb   $0x0,0xf01073fd
f0100b13:	0f 85 92 01 00 00    	jne    f0100cab <debuginfo_eip+0x200>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b19:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b20:	b8 d4 5a 10 f0       	mov    $0xf0105ad4,%eax
f0100b25:	2d 9c 20 10 f0       	sub    $0xf010209c,%eax
f0100b2a:	c1 f8 02             	sar    $0x2,%eax
f0100b2d:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b33:	83 e8 01             	sub    $0x1,%eax
f0100b36:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b39:	83 ec 08             	sub    $0x8,%esp
f0100b3c:	56                   	push   %esi
f0100b3d:	6a 64                	push   $0x64
f0100b3f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b42:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b45:	b8 9c 20 10 f0       	mov    $0xf010209c,%eax
f0100b4a:	e8 66 fe ff ff       	call   f01009b5 <stab_binsearch>
	if (lfile == 0)
f0100b4f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b52:	83 c4 10             	add    $0x10,%esp
f0100b55:	85 c0                	test   %eax,%eax
f0100b57:	0f 84 55 01 00 00    	je     f0100cb2 <debuginfo_eip+0x207>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b5d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b60:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b63:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b66:	83 ec 08             	sub    $0x8,%esp
f0100b69:	56                   	push   %esi
f0100b6a:	6a 24                	push   $0x24
f0100b6c:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b6f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b72:	b8 9c 20 10 f0       	mov    $0xf010209c,%eax
f0100b77:	e8 39 fe ff ff       	call   f01009b5 <stab_binsearch>

	if (lfun <= rfun) {
f0100b7c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b7f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b82:	83 c4 10             	add    $0x10,%esp
f0100b85:	39 d0                	cmp    %edx,%eax
f0100b87:	7f 40                	jg     f0100bc9 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b89:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b8c:	c1 e1 02             	shl    $0x2,%ecx
f0100b8f:	8d b9 9c 20 10 f0    	lea    -0xfefdf64(%ecx),%edi
f0100b95:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b98:	8b b9 9c 20 10 f0    	mov    -0xfefdf64(%ecx),%edi
f0100b9e:	b9 fe 73 10 f0       	mov    $0xf01073fe,%ecx
f0100ba3:	81 e9 d5 5a 10 f0    	sub    $0xf0105ad5,%ecx
f0100ba9:	39 cf                	cmp    %ecx,%edi
f0100bab:	73 09                	jae    f0100bb6 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bad:	81 c7 d5 5a 10 f0    	add    $0xf0105ad5,%edi
f0100bb3:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bb6:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bb9:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bbc:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100bbf:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bc1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bc4:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100bc7:	eb 0f                	jmp    f0100bd8 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bc9:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bcc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bcf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bd2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bd5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bd8:	83 ec 08             	sub    $0x8,%esp
f0100bdb:	6a 3a                	push   $0x3a
f0100bdd:	ff 73 08             	pushl  0x8(%ebx)
f0100be0:	e8 5b 08 00 00       	call   f0101440 <strfind>
f0100be5:	2b 43 08             	sub    0x8(%ebx),%eax
f0100be8:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	//(N_SLINE)
	stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
f0100beb:	83 c4 08             	add    $0x8,%esp
f0100bee:	56                   	push   %esi
f0100bef:	6a 44                	push   $0x44
f0100bf1:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100bf4:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100bf7:	b8 9c 20 10 f0       	mov    $0xf010209c,%eax
f0100bfc:	e8 b4 fd ff ff       	call   f01009b5 <stab_binsearch>
	if (lline>rline) return -1;
f0100c01:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c04:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100c07:	83 c4 10             	add    $0x10,%esp
f0100c0a:	39 d0                	cmp    %edx,%eax
f0100c0c:	0f 8f a7 00 00 00    	jg     f0100cb9 <debuginfo_eip+0x20e>
	info->eip_line = rline-lfile;
f0100c12:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c15:	29 fa                	sub    %edi,%edx
f0100c17:	89 53 04             	mov    %edx,0x4(%ebx)
f0100c1a:	89 c2                	mov    %eax,%edx
f0100c1c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100c1f:	8d 04 85 9c 20 10 f0 	lea    -0xfefdf64(,%eax,4),%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c26:	eb 06                	jmp    f0100c2e <debuginfo_eip+0x183>
f0100c28:	83 ea 01             	sub    $0x1,%edx
f0100c2b:	83 e8 0c             	sub    $0xc,%eax
f0100c2e:	39 d7                	cmp    %edx,%edi
f0100c30:	7f 34                	jg     f0100c66 <debuginfo_eip+0x1bb>
	       && stabs[lline].n_type != N_SOL
f0100c32:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100c36:	80 f9 84             	cmp    $0x84,%cl
f0100c39:	74 0b                	je     f0100c46 <debuginfo_eip+0x19b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c3b:	80 f9 64             	cmp    $0x64,%cl
f0100c3e:	75 e8                	jne    f0100c28 <debuginfo_eip+0x17d>
f0100c40:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c44:	74 e2                	je     f0100c28 <debuginfo_eip+0x17d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c46:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c49:	8b 14 85 9c 20 10 f0 	mov    -0xfefdf64(,%eax,4),%edx
f0100c50:	b8 fe 73 10 f0       	mov    $0xf01073fe,%eax
f0100c55:	2d d5 5a 10 f0       	sub    $0xf0105ad5,%eax
f0100c5a:	39 c2                	cmp    %eax,%edx
f0100c5c:	73 08                	jae    f0100c66 <debuginfo_eip+0x1bb>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c5e:	81 c2 d5 5a 10 f0    	add    $0xf0105ad5,%edx
f0100c64:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c66:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c69:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c6c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c71:	39 f2                	cmp    %esi,%edx
f0100c73:	7d 50                	jge    f0100cc5 <debuginfo_eip+0x21a>
		for (lline = lfun + 1;
f0100c75:	83 c2 01             	add    $0x1,%edx
f0100c78:	89 d0                	mov    %edx,%eax
f0100c7a:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c7d:	8d 14 95 9c 20 10 f0 	lea    -0xfefdf64(,%edx,4),%edx
f0100c84:	eb 04                	jmp    f0100c8a <debuginfo_eip+0x1df>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c86:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c8a:	39 c6                	cmp    %eax,%esi
f0100c8c:	7e 32                	jle    f0100cc0 <debuginfo_eip+0x215>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c8e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c92:	83 c0 01             	add    $0x1,%eax
f0100c95:	83 c2 0c             	add    $0xc,%edx
f0100c98:	80 f9 a0             	cmp    $0xa0,%cl
f0100c9b:	74 e9                	je     f0100c86 <debuginfo_eip+0x1db>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c9d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ca2:	eb 21                	jmp    f0100cc5 <debuginfo_eip+0x21a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100ca4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca9:	eb 1a                	jmp    f0100cc5 <debuginfo_eip+0x21a>
f0100cab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cb0:	eb 13                	jmp    f0100cc5 <debuginfo_eip+0x21a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100cb2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cb7:	eb 0c                	jmp    f0100cc5 <debuginfo_eip+0x21a>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	//(N_SLINE)
	stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
	if (lline>rline) return -1;
f0100cb9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cbe:	eb 05                	jmp    f0100cc5 <debuginfo_eip+0x21a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cc0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cc5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cc8:	5b                   	pop    %ebx
f0100cc9:	5e                   	pop    %esi
f0100cca:	5f                   	pop    %edi
f0100ccb:	5d                   	pop    %ebp
f0100ccc:	c3                   	ret    

f0100ccd <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100ccd:	55                   	push   %ebp
f0100cce:	89 e5                	mov    %esp,%ebp
f0100cd0:	57                   	push   %edi
f0100cd1:	56                   	push   %esi
f0100cd2:	53                   	push   %ebx
f0100cd3:	83 ec 1c             	sub    $0x1c,%esp
f0100cd6:	89 c7                	mov    %eax,%edi
f0100cd8:	89 d6                	mov    %edx,%esi
f0100cda:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cdd:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100ce0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ce3:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100ce6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100ce9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cee:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100cf1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100cf4:	39 d3                	cmp    %edx,%ebx
f0100cf6:	72 05                	jb     f0100cfd <printnum+0x30>
f0100cf8:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100cfb:	77 45                	ja     f0100d42 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100cfd:	83 ec 0c             	sub    $0xc,%esp
f0100d00:	ff 75 18             	pushl  0x18(%ebp)
f0100d03:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d06:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100d09:	53                   	push   %ebx
f0100d0a:	ff 75 10             	pushl  0x10(%ebp)
f0100d0d:	83 ec 08             	sub    $0x8,%esp
f0100d10:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d13:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d16:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d19:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d1c:	e8 3f 09 00 00       	call   f0101660 <__udivdi3>
f0100d21:	83 c4 18             	add    $0x18,%esp
f0100d24:	52                   	push   %edx
f0100d25:	50                   	push   %eax
f0100d26:	89 f2                	mov    %esi,%edx
f0100d28:	89 f8                	mov    %edi,%eax
f0100d2a:	e8 9e ff ff ff       	call   f0100ccd <printnum>
f0100d2f:	83 c4 20             	add    $0x20,%esp
f0100d32:	eb 18                	jmp    f0100d4c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d34:	83 ec 08             	sub    $0x8,%esp
f0100d37:	56                   	push   %esi
f0100d38:	ff 75 18             	pushl  0x18(%ebp)
f0100d3b:	ff d7                	call   *%edi
f0100d3d:	83 c4 10             	add    $0x10,%esp
f0100d40:	eb 03                	jmp    f0100d45 <printnum+0x78>
f0100d42:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d45:	83 eb 01             	sub    $0x1,%ebx
f0100d48:	85 db                	test   %ebx,%ebx
f0100d4a:	7f e8                	jg     f0100d34 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d4c:	83 ec 08             	sub    $0x8,%esp
f0100d4f:	56                   	push   %esi
f0100d50:	83 ec 04             	sub    $0x4,%esp
f0100d53:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d56:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d59:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d5c:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d5f:	e8 2c 0a 00 00       	call   f0101790 <__umoddi3>
f0100d64:	83 c4 14             	add    $0x14,%esp
f0100d67:	0f be 80 89 1e 10 f0 	movsbl -0xfefe177(%eax),%eax
f0100d6e:	50                   	push   %eax
f0100d6f:	ff d7                	call   *%edi
}
f0100d71:	83 c4 10             	add    $0x10,%esp
f0100d74:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d77:	5b                   	pop    %ebx
f0100d78:	5e                   	pop    %esi
f0100d79:	5f                   	pop    %edi
f0100d7a:	5d                   	pop    %ebp
f0100d7b:	c3                   	ret    

f0100d7c <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d7c:	55                   	push   %ebp
f0100d7d:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d7f:	83 fa 01             	cmp    $0x1,%edx
f0100d82:	7e 0e                	jle    f0100d92 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d84:	8b 10                	mov    (%eax),%edx
f0100d86:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d89:	89 08                	mov    %ecx,(%eax)
f0100d8b:	8b 02                	mov    (%edx),%eax
f0100d8d:	8b 52 04             	mov    0x4(%edx),%edx
f0100d90:	eb 22                	jmp    f0100db4 <getuint+0x38>
	else if (lflag)
f0100d92:	85 d2                	test   %edx,%edx
f0100d94:	74 10                	je     f0100da6 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d96:	8b 10                	mov    (%eax),%edx
f0100d98:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d9b:	89 08                	mov    %ecx,(%eax)
f0100d9d:	8b 02                	mov    (%edx),%eax
f0100d9f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100da4:	eb 0e                	jmp    f0100db4 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100da6:	8b 10                	mov    (%eax),%edx
f0100da8:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dab:	89 08                	mov    %ecx,(%eax)
f0100dad:	8b 02                	mov    (%edx),%eax
f0100daf:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100db4:	5d                   	pop    %ebp
f0100db5:	c3                   	ret    

f0100db6 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100db6:	55                   	push   %ebp
f0100db7:	89 e5                	mov    %esp,%ebp
f0100db9:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100dbc:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100dc0:	8b 10                	mov    (%eax),%edx
f0100dc2:	3b 50 04             	cmp    0x4(%eax),%edx
f0100dc5:	73 0a                	jae    f0100dd1 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100dc7:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100dca:	89 08                	mov    %ecx,(%eax)
f0100dcc:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dcf:	88 02                	mov    %al,(%edx)
}
f0100dd1:	5d                   	pop    %ebp
f0100dd2:	c3                   	ret    

f0100dd3 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100dd3:	55                   	push   %ebp
f0100dd4:	89 e5                	mov    %esp,%ebp
f0100dd6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100dd9:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ddc:	50                   	push   %eax
f0100ddd:	ff 75 10             	pushl  0x10(%ebp)
f0100de0:	ff 75 0c             	pushl  0xc(%ebp)
f0100de3:	ff 75 08             	pushl  0x8(%ebp)
f0100de6:	e8 05 00 00 00       	call   f0100df0 <vprintfmt>
	va_end(ap);
}
f0100deb:	83 c4 10             	add    $0x10,%esp
f0100dee:	c9                   	leave  
f0100def:	c3                   	ret    

f0100df0 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100df0:	55                   	push   %ebp
f0100df1:	89 e5                	mov    %esp,%ebp
f0100df3:	57                   	push   %edi
f0100df4:	56                   	push   %esi
f0100df5:	53                   	push   %ebx
f0100df6:	83 ec 2c             	sub    $0x2c,%esp
f0100df9:	8b 75 08             	mov    0x8(%ebp),%esi
f0100dfc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100dff:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e02:	eb 12                	jmp    f0100e16 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e04:	85 c0                	test   %eax,%eax
f0100e06:	0f 84 89 03 00 00    	je     f0101195 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0100e0c:	83 ec 08             	sub    $0x8,%esp
f0100e0f:	53                   	push   %ebx
f0100e10:	50                   	push   %eax
f0100e11:	ff d6                	call   *%esi
f0100e13:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e16:	83 c7 01             	add    $0x1,%edi
f0100e19:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e1d:	83 f8 25             	cmp    $0x25,%eax
f0100e20:	75 e2                	jne    f0100e04 <vprintfmt+0x14>
f0100e22:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e26:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e2d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e34:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e3b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e40:	eb 07                	jmp    f0100e49 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e42:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e45:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e49:	8d 47 01             	lea    0x1(%edi),%eax
f0100e4c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e4f:	0f b6 07             	movzbl (%edi),%eax
f0100e52:	0f b6 c8             	movzbl %al,%ecx
f0100e55:	83 e8 23             	sub    $0x23,%eax
f0100e58:	3c 55                	cmp    $0x55,%al
f0100e5a:	0f 87 1a 03 00 00    	ja     f010117a <vprintfmt+0x38a>
f0100e60:	0f b6 c0             	movzbl %al,%eax
f0100e63:	ff 24 85 18 1f 10 f0 	jmp    *-0xfefe0e8(,%eax,4)
f0100e6a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e6d:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e71:	eb d6                	jmp    f0100e49 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e73:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e76:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e7b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e7e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e81:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100e85:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100e88:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100e8b:	83 fa 09             	cmp    $0x9,%edx
f0100e8e:	77 39                	ja     f0100ec9 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e90:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e93:	eb e9                	jmp    f0100e7e <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e95:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e98:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e9b:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e9e:	8b 00                	mov    (%eax),%eax
f0100ea0:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100ea6:	eb 27                	jmp    f0100ecf <vprintfmt+0xdf>
f0100ea8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eab:	85 c0                	test   %eax,%eax
f0100ead:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100eb2:	0f 49 c8             	cmovns %eax,%ecx
f0100eb5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ebb:	eb 8c                	jmp    f0100e49 <vprintfmt+0x59>
f0100ebd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100ec0:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100ec7:	eb 80                	jmp    f0100e49 <vprintfmt+0x59>
f0100ec9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ecc:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100ecf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ed3:	0f 89 70 ff ff ff    	jns    f0100e49 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100ed9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100edc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100edf:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100ee6:	e9 5e ff ff ff       	jmp    f0100e49 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100eeb:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100ef1:	e9 53 ff ff ff       	jmp    f0100e49 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ef6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ef9:	8d 50 04             	lea    0x4(%eax),%edx
f0100efc:	89 55 14             	mov    %edx,0x14(%ebp)
f0100eff:	83 ec 08             	sub    $0x8,%esp
f0100f02:	53                   	push   %ebx
f0100f03:	ff 30                	pushl  (%eax)
f0100f05:	ff d6                	call   *%esi
			break;
f0100f07:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f0a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100f0d:	e9 04 ff ff ff       	jmp    f0100e16 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f12:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f15:	8d 50 04             	lea    0x4(%eax),%edx
f0100f18:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f1b:	8b 00                	mov    (%eax),%eax
f0100f1d:	99                   	cltd   
f0100f1e:	31 d0                	xor    %edx,%eax
f0100f20:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f22:	83 f8 06             	cmp    $0x6,%eax
f0100f25:	7f 0b                	jg     f0100f32 <vprintfmt+0x142>
f0100f27:	8b 14 85 70 20 10 f0 	mov    -0xfefdf90(,%eax,4),%edx
f0100f2e:	85 d2                	test   %edx,%edx
f0100f30:	75 18                	jne    f0100f4a <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100f32:	50                   	push   %eax
f0100f33:	68 a1 1e 10 f0       	push   $0xf0101ea1
f0100f38:	53                   	push   %ebx
f0100f39:	56                   	push   %esi
f0100f3a:	e8 94 fe ff ff       	call   f0100dd3 <printfmt>
f0100f3f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f42:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f45:	e9 cc fe ff ff       	jmp    f0100e16 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100f4a:	52                   	push   %edx
f0100f4b:	68 aa 1e 10 f0       	push   $0xf0101eaa
f0100f50:	53                   	push   %ebx
f0100f51:	56                   	push   %esi
f0100f52:	e8 7c fe ff ff       	call   f0100dd3 <printfmt>
f0100f57:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f5d:	e9 b4 fe ff ff       	jmp    f0100e16 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f62:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f65:	8d 50 04             	lea    0x4(%eax),%edx
f0100f68:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f6b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f6d:	85 ff                	test   %edi,%edi
f0100f6f:	b8 9a 1e 10 f0       	mov    $0xf0101e9a,%eax
f0100f74:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f77:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f7b:	0f 8e 94 00 00 00    	jle    f0101015 <vprintfmt+0x225>
f0100f81:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f85:	0f 84 98 00 00 00    	je     f0101023 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f8b:	83 ec 08             	sub    $0x8,%esp
f0100f8e:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f91:	57                   	push   %edi
f0100f92:	e8 5f 03 00 00       	call   f01012f6 <strnlen>
f0100f97:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f9a:	29 c1                	sub    %eax,%ecx
f0100f9c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100f9f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100fa2:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100fa6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fa9:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100fac:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fae:	eb 0f                	jmp    f0100fbf <vprintfmt+0x1cf>
					putch(padc, putdat);
f0100fb0:	83 ec 08             	sub    $0x8,%esp
f0100fb3:	53                   	push   %ebx
f0100fb4:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fb7:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fb9:	83 ef 01             	sub    $0x1,%edi
f0100fbc:	83 c4 10             	add    $0x10,%esp
f0100fbf:	85 ff                	test   %edi,%edi
f0100fc1:	7f ed                	jg     f0100fb0 <vprintfmt+0x1c0>
f0100fc3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100fc6:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100fc9:	85 c9                	test   %ecx,%ecx
f0100fcb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fd0:	0f 49 c1             	cmovns %ecx,%eax
f0100fd3:	29 c1                	sub    %eax,%ecx
f0100fd5:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fd8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fdb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fde:	89 cb                	mov    %ecx,%ebx
f0100fe0:	eb 4d                	jmp    f010102f <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fe2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fe6:	74 1b                	je     f0101003 <vprintfmt+0x213>
f0100fe8:	0f be c0             	movsbl %al,%eax
f0100feb:	83 e8 20             	sub    $0x20,%eax
f0100fee:	83 f8 5e             	cmp    $0x5e,%eax
f0100ff1:	76 10                	jbe    f0101003 <vprintfmt+0x213>
					putch('?', putdat);
f0100ff3:	83 ec 08             	sub    $0x8,%esp
f0100ff6:	ff 75 0c             	pushl  0xc(%ebp)
f0100ff9:	6a 3f                	push   $0x3f
f0100ffb:	ff 55 08             	call   *0x8(%ebp)
f0100ffe:	83 c4 10             	add    $0x10,%esp
f0101001:	eb 0d                	jmp    f0101010 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0101003:	83 ec 08             	sub    $0x8,%esp
f0101006:	ff 75 0c             	pushl  0xc(%ebp)
f0101009:	52                   	push   %edx
f010100a:	ff 55 08             	call   *0x8(%ebp)
f010100d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101010:	83 eb 01             	sub    $0x1,%ebx
f0101013:	eb 1a                	jmp    f010102f <vprintfmt+0x23f>
f0101015:	89 75 08             	mov    %esi,0x8(%ebp)
f0101018:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010101b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010101e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101021:	eb 0c                	jmp    f010102f <vprintfmt+0x23f>
f0101023:	89 75 08             	mov    %esi,0x8(%ebp)
f0101026:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101029:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010102c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010102f:	83 c7 01             	add    $0x1,%edi
f0101032:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101036:	0f be d0             	movsbl %al,%edx
f0101039:	85 d2                	test   %edx,%edx
f010103b:	74 23                	je     f0101060 <vprintfmt+0x270>
f010103d:	85 f6                	test   %esi,%esi
f010103f:	78 a1                	js     f0100fe2 <vprintfmt+0x1f2>
f0101041:	83 ee 01             	sub    $0x1,%esi
f0101044:	79 9c                	jns    f0100fe2 <vprintfmt+0x1f2>
f0101046:	89 df                	mov    %ebx,%edi
f0101048:	8b 75 08             	mov    0x8(%ebp),%esi
f010104b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010104e:	eb 18                	jmp    f0101068 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101050:	83 ec 08             	sub    $0x8,%esp
f0101053:	53                   	push   %ebx
f0101054:	6a 20                	push   $0x20
f0101056:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101058:	83 ef 01             	sub    $0x1,%edi
f010105b:	83 c4 10             	add    $0x10,%esp
f010105e:	eb 08                	jmp    f0101068 <vprintfmt+0x278>
f0101060:	89 df                	mov    %ebx,%edi
f0101062:	8b 75 08             	mov    0x8(%ebp),%esi
f0101065:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101068:	85 ff                	test   %edi,%edi
f010106a:	7f e4                	jg     f0101050 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010106c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010106f:	e9 a2 fd ff ff       	jmp    f0100e16 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101074:	83 fa 01             	cmp    $0x1,%edx
f0101077:	7e 16                	jle    f010108f <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101079:	8b 45 14             	mov    0x14(%ebp),%eax
f010107c:	8d 50 08             	lea    0x8(%eax),%edx
f010107f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101082:	8b 50 04             	mov    0x4(%eax),%edx
f0101085:	8b 00                	mov    (%eax),%eax
f0101087:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010108a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010108d:	eb 32                	jmp    f01010c1 <vprintfmt+0x2d1>
	else if (lflag)
f010108f:	85 d2                	test   %edx,%edx
f0101091:	74 18                	je     f01010ab <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101093:	8b 45 14             	mov    0x14(%ebp),%eax
f0101096:	8d 50 04             	lea    0x4(%eax),%edx
f0101099:	89 55 14             	mov    %edx,0x14(%ebp)
f010109c:	8b 00                	mov    (%eax),%eax
f010109e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010a1:	89 c1                	mov    %eax,%ecx
f01010a3:	c1 f9 1f             	sar    $0x1f,%ecx
f01010a6:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01010a9:	eb 16                	jmp    f01010c1 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f01010ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ae:	8d 50 04             	lea    0x4(%eax),%edx
f01010b1:	89 55 14             	mov    %edx,0x14(%ebp)
f01010b4:	8b 00                	mov    (%eax),%eax
f01010b6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010b9:	89 c1                	mov    %eax,%ecx
f01010bb:	c1 f9 1f             	sar    $0x1f,%ecx
f01010be:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010c1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010c4:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010c7:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010cc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010d0:	79 74                	jns    f0101146 <vprintfmt+0x356>
				putch('-', putdat);
f01010d2:	83 ec 08             	sub    $0x8,%esp
f01010d5:	53                   	push   %ebx
f01010d6:	6a 2d                	push   $0x2d
f01010d8:	ff d6                	call   *%esi
				num = -(long long) num;
f01010da:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010dd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010e0:	f7 d8                	neg    %eax
f01010e2:	83 d2 00             	adc    $0x0,%edx
f01010e5:	f7 da                	neg    %edx
f01010e7:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01010ea:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010ef:	eb 55                	jmp    f0101146 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010f1:	8d 45 14             	lea    0x14(%ebp),%eax
f01010f4:	e8 83 fc ff ff       	call   f0100d7c <getuint>
			base = 10;
f01010f9:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010fe:	eb 46                	jmp    f0101146 <vprintfmt+0x356>
			// Replace this with your code.
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f0101100:	8d 45 14             	lea    0x14(%ebp),%eax
f0101103:	e8 74 fc ff ff       	call   f0100d7c <getuint>
			base = 8;
f0101108:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010110d:	eb 37                	jmp    f0101146 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f010110f:	83 ec 08             	sub    $0x8,%esp
f0101112:	53                   	push   %ebx
f0101113:	6a 30                	push   $0x30
f0101115:	ff d6                	call   *%esi
			putch('x', putdat);
f0101117:	83 c4 08             	add    $0x8,%esp
f010111a:	53                   	push   %ebx
f010111b:	6a 78                	push   $0x78
f010111d:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010111f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101122:	8d 50 04             	lea    0x4(%eax),%edx
f0101125:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101128:	8b 00                	mov    (%eax),%eax
f010112a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010112f:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101132:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101137:	eb 0d                	jmp    f0101146 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101139:	8d 45 14             	lea    0x14(%ebp),%eax
f010113c:	e8 3b fc ff ff       	call   f0100d7c <getuint>
			base = 16;
f0101141:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101146:	83 ec 0c             	sub    $0xc,%esp
f0101149:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010114d:	57                   	push   %edi
f010114e:	ff 75 e0             	pushl  -0x20(%ebp)
f0101151:	51                   	push   %ecx
f0101152:	52                   	push   %edx
f0101153:	50                   	push   %eax
f0101154:	89 da                	mov    %ebx,%edx
f0101156:	89 f0                	mov    %esi,%eax
f0101158:	e8 70 fb ff ff       	call   f0100ccd <printnum>
			break;
f010115d:	83 c4 20             	add    $0x20,%esp
f0101160:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101163:	e9 ae fc ff ff       	jmp    f0100e16 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101168:	83 ec 08             	sub    $0x8,%esp
f010116b:	53                   	push   %ebx
f010116c:	51                   	push   %ecx
f010116d:	ff d6                	call   *%esi
			break;
f010116f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101172:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101175:	e9 9c fc ff ff       	jmp    f0100e16 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010117a:	83 ec 08             	sub    $0x8,%esp
f010117d:	53                   	push   %ebx
f010117e:	6a 25                	push   $0x25
f0101180:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101182:	83 c4 10             	add    $0x10,%esp
f0101185:	eb 03                	jmp    f010118a <vprintfmt+0x39a>
f0101187:	83 ef 01             	sub    $0x1,%edi
f010118a:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010118e:	75 f7                	jne    f0101187 <vprintfmt+0x397>
f0101190:	e9 81 fc ff ff       	jmp    f0100e16 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101195:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101198:	5b                   	pop    %ebx
f0101199:	5e                   	pop    %esi
f010119a:	5f                   	pop    %edi
f010119b:	5d                   	pop    %ebp
f010119c:	c3                   	ret    

f010119d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010119d:	55                   	push   %ebp
f010119e:	89 e5                	mov    %esp,%ebp
f01011a0:	83 ec 18             	sub    $0x18,%esp
f01011a3:	8b 45 08             	mov    0x8(%ebp),%eax
f01011a6:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011a9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011ac:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011b0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011b3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011ba:	85 c0                	test   %eax,%eax
f01011bc:	74 26                	je     f01011e4 <vsnprintf+0x47>
f01011be:	85 d2                	test   %edx,%edx
f01011c0:	7e 22                	jle    f01011e4 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011c2:	ff 75 14             	pushl  0x14(%ebp)
f01011c5:	ff 75 10             	pushl  0x10(%ebp)
f01011c8:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011cb:	50                   	push   %eax
f01011cc:	68 b6 0d 10 f0       	push   $0xf0100db6
f01011d1:	e8 1a fc ff ff       	call   f0100df0 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011d9:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011df:	83 c4 10             	add    $0x10,%esp
f01011e2:	eb 05                	jmp    f01011e9 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011e4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011e9:	c9                   	leave  
f01011ea:	c3                   	ret    

f01011eb <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011eb:	55                   	push   %ebp
f01011ec:	89 e5                	mov    %esp,%ebp
f01011ee:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011f1:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011f4:	50                   	push   %eax
f01011f5:	ff 75 10             	pushl  0x10(%ebp)
f01011f8:	ff 75 0c             	pushl  0xc(%ebp)
f01011fb:	ff 75 08             	pushl  0x8(%ebp)
f01011fe:	e8 9a ff ff ff       	call   f010119d <vsnprintf>
	va_end(ap);

	return rc;
}
f0101203:	c9                   	leave  
f0101204:	c3                   	ret    

f0101205 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101205:	55                   	push   %ebp
f0101206:	89 e5                	mov    %esp,%ebp
f0101208:	57                   	push   %edi
f0101209:	56                   	push   %esi
f010120a:	53                   	push   %ebx
f010120b:	83 ec 0c             	sub    $0xc,%esp
f010120e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101211:	85 c0                	test   %eax,%eax
f0101213:	74 11                	je     f0101226 <readline+0x21>
		cprintf("%s", prompt);
f0101215:	83 ec 08             	sub    $0x8,%esp
f0101218:	50                   	push   %eax
f0101219:	68 aa 1e 10 f0       	push   $0xf0101eaa
f010121e:	e8 7e f7 ff ff       	call   f01009a1 <cprintf>
f0101223:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101226:	83 ec 0c             	sub    $0xc,%esp
f0101229:	6a 00                	push   $0x0
f010122b:	e8 4c f4 ff ff       	call   f010067c <iscons>
f0101230:	89 c7                	mov    %eax,%edi
f0101232:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101235:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010123a:	e8 2c f4 ff ff       	call   f010066b <getchar>
f010123f:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101241:	85 c0                	test   %eax,%eax
f0101243:	79 18                	jns    f010125d <readline+0x58>
			cprintf("read error: %e\n", c);
f0101245:	83 ec 08             	sub    $0x8,%esp
f0101248:	50                   	push   %eax
f0101249:	68 8c 20 10 f0       	push   $0xf010208c
f010124e:	e8 4e f7 ff ff       	call   f01009a1 <cprintf>
			return NULL;
f0101253:	83 c4 10             	add    $0x10,%esp
f0101256:	b8 00 00 00 00       	mov    $0x0,%eax
f010125b:	eb 79                	jmp    f01012d6 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010125d:	83 f8 08             	cmp    $0x8,%eax
f0101260:	0f 94 c2             	sete   %dl
f0101263:	83 f8 7f             	cmp    $0x7f,%eax
f0101266:	0f 94 c0             	sete   %al
f0101269:	08 c2                	or     %al,%dl
f010126b:	74 1a                	je     f0101287 <readline+0x82>
f010126d:	85 f6                	test   %esi,%esi
f010126f:	7e 16                	jle    f0101287 <readline+0x82>
			if (echoing)
f0101271:	85 ff                	test   %edi,%edi
f0101273:	74 0d                	je     f0101282 <readline+0x7d>
				cputchar('\b');
f0101275:	83 ec 0c             	sub    $0xc,%esp
f0101278:	6a 08                	push   $0x8
f010127a:	e8 dc f3 ff ff       	call   f010065b <cputchar>
f010127f:	83 c4 10             	add    $0x10,%esp
			i--;
f0101282:	83 ee 01             	sub    $0x1,%esi
f0101285:	eb b3                	jmp    f010123a <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101287:	83 fb 1f             	cmp    $0x1f,%ebx
f010128a:	7e 23                	jle    f01012af <readline+0xaa>
f010128c:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101292:	7f 1b                	jg     f01012af <readline+0xaa>
			if (echoing)
f0101294:	85 ff                	test   %edi,%edi
f0101296:	74 0c                	je     f01012a4 <readline+0x9f>
				cputchar(c);
f0101298:	83 ec 0c             	sub    $0xc,%esp
f010129b:	53                   	push   %ebx
f010129c:	e8 ba f3 ff ff       	call   f010065b <cputchar>
f01012a1:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01012a4:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012aa:	8d 76 01             	lea    0x1(%esi),%esi
f01012ad:	eb 8b                	jmp    f010123a <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01012af:	83 fb 0a             	cmp    $0xa,%ebx
f01012b2:	74 05                	je     f01012b9 <readline+0xb4>
f01012b4:	83 fb 0d             	cmp    $0xd,%ebx
f01012b7:	75 81                	jne    f010123a <readline+0x35>
			if (echoing)
f01012b9:	85 ff                	test   %edi,%edi
f01012bb:	74 0d                	je     f01012ca <readline+0xc5>
				cputchar('\n');
f01012bd:	83 ec 0c             	sub    $0xc,%esp
f01012c0:	6a 0a                	push   $0xa
f01012c2:	e8 94 f3 ff ff       	call   f010065b <cputchar>
f01012c7:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01012ca:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012d1:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01012d6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012d9:	5b                   	pop    %ebx
f01012da:	5e                   	pop    %esi
f01012db:	5f                   	pop    %edi
f01012dc:	5d                   	pop    %ebp
f01012dd:	c3                   	ret    

f01012de <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012de:	55                   	push   %ebp
f01012df:	89 e5                	mov    %esp,%ebp
f01012e1:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01012e9:	eb 03                	jmp    f01012ee <strlen+0x10>
		n++;
f01012eb:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012ee:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012f2:	75 f7                	jne    f01012eb <strlen+0xd>
		n++;
	return n;
}
f01012f4:	5d                   	pop    %ebp
f01012f5:	c3                   	ret    

f01012f6 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012f6:	55                   	push   %ebp
f01012f7:	89 e5                	mov    %esp,%ebp
f01012f9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012fc:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012ff:	ba 00 00 00 00       	mov    $0x0,%edx
f0101304:	eb 03                	jmp    f0101309 <strnlen+0x13>
		n++;
f0101306:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101309:	39 c2                	cmp    %eax,%edx
f010130b:	74 08                	je     f0101315 <strnlen+0x1f>
f010130d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101311:	75 f3                	jne    f0101306 <strnlen+0x10>
f0101313:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101315:	5d                   	pop    %ebp
f0101316:	c3                   	ret    

f0101317 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101317:	55                   	push   %ebp
f0101318:	89 e5                	mov    %esp,%ebp
f010131a:	53                   	push   %ebx
f010131b:	8b 45 08             	mov    0x8(%ebp),%eax
f010131e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101321:	89 c2                	mov    %eax,%edx
f0101323:	83 c2 01             	add    $0x1,%edx
f0101326:	83 c1 01             	add    $0x1,%ecx
f0101329:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010132d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101330:	84 db                	test   %bl,%bl
f0101332:	75 ef                	jne    f0101323 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101334:	5b                   	pop    %ebx
f0101335:	5d                   	pop    %ebp
f0101336:	c3                   	ret    

f0101337 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101337:	55                   	push   %ebp
f0101338:	89 e5                	mov    %esp,%ebp
f010133a:	53                   	push   %ebx
f010133b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010133e:	53                   	push   %ebx
f010133f:	e8 9a ff ff ff       	call   f01012de <strlen>
f0101344:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101347:	ff 75 0c             	pushl  0xc(%ebp)
f010134a:	01 d8                	add    %ebx,%eax
f010134c:	50                   	push   %eax
f010134d:	e8 c5 ff ff ff       	call   f0101317 <strcpy>
	return dst;
}
f0101352:	89 d8                	mov    %ebx,%eax
f0101354:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101357:	c9                   	leave  
f0101358:	c3                   	ret    

f0101359 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101359:	55                   	push   %ebp
f010135a:	89 e5                	mov    %esp,%ebp
f010135c:	56                   	push   %esi
f010135d:	53                   	push   %ebx
f010135e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101361:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101364:	89 f3                	mov    %esi,%ebx
f0101366:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101369:	89 f2                	mov    %esi,%edx
f010136b:	eb 0f                	jmp    f010137c <strncpy+0x23>
		*dst++ = *src;
f010136d:	83 c2 01             	add    $0x1,%edx
f0101370:	0f b6 01             	movzbl (%ecx),%eax
f0101373:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101376:	80 39 01             	cmpb   $0x1,(%ecx)
f0101379:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010137c:	39 da                	cmp    %ebx,%edx
f010137e:	75 ed                	jne    f010136d <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101380:	89 f0                	mov    %esi,%eax
f0101382:	5b                   	pop    %ebx
f0101383:	5e                   	pop    %esi
f0101384:	5d                   	pop    %ebp
f0101385:	c3                   	ret    

f0101386 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101386:	55                   	push   %ebp
f0101387:	89 e5                	mov    %esp,%ebp
f0101389:	56                   	push   %esi
f010138a:	53                   	push   %ebx
f010138b:	8b 75 08             	mov    0x8(%ebp),%esi
f010138e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101391:	8b 55 10             	mov    0x10(%ebp),%edx
f0101394:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101396:	85 d2                	test   %edx,%edx
f0101398:	74 21                	je     f01013bb <strlcpy+0x35>
f010139a:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010139e:	89 f2                	mov    %esi,%edx
f01013a0:	eb 09                	jmp    f01013ab <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013a2:	83 c2 01             	add    $0x1,%edx
f01013a5:	83 c1 01             	add    $0x1,%ecx
f01013a8:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013ab:	39 c2                	cmp    %eax,%edx
f01013ad:	74 09                	je     f01013b8 <strlcpy+0x32>
f01013af:	0f b6 19             	movzbl (%ecx),%ebx
f01013b2:	84 db                	test   %bl,%bl
f01013b4:	75 ec                	jne    f01013a2 <strlcpy+0x1c>
f01013b6:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013b8:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013bb:	29 f0                	sub    %esi,%eax
}
f01013bd:	5b                   	pop    %ebx
f01013be:	5e                   	pop    %esi
f01013bf:	5d                   	pop    %ebp
f01013c0:	c3                   	ret    

f01013c1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013c1:	55                   	push   %ebp
f01013c2:	89 e5                	mov    %esp,%ebp
f01013c4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013c7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013ca:	eb 06                	jmp    f01013d2 <strcmp+0x11>
		p++, q++;
f01013cc:	83 c1 01             	add    $0x1,%ecx
f01013cf:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013d2:	0f b6 01             	movzbl (%ecx),%eax
f01013d5:	84 c0                	test   %al,%al
f01013d7:	74 04                	je     f01013dd <strcmp+0x1c>
f01013d9:	3a 02                	cmp    (%edx),%al
f01013db:	74 ef                	je     f01013cc <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013dd:	0f b6 c0             	movzbl %al,%eax
f01013e0:	0f b6 12             	movzbl (%edx),%edx
f01013e3:	29 d0                	sub    %edx,%eax
}
f01013e5:	5d                   	pop    %ebp
f01013e6:	c3                   	ret    

f01013e7 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013e7:	55                   	push   %ebp
f01013e8:	89 e5                	mov    %esp,%ebp
f01013ea:	53                   	push   %ebx
f01013eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ee:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013f1:	89 c3                	mov    %eax,%ebx
f01013f3:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01013f6:	eb 06                	jmp    f01013fe <strncmp+0x17>
		n--, p++, q++;
f01013f8:	83 c0 01             	add    $0x1,%eax
f01013fb:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013fe:	39 d8                	cmp    %ebx,%eax
f0101400:	74 15                	je     f0101417 <strncmp+0x30>
f0101402:	0f b6 08             	movzbl (%eax),%ecx
f0101405:	84 c9                	test   %cl,%cl
f0101407:	74 04                	je     f010140d <strncmp+0x26>
f0101409:	3a 0a                	cmp    (%edx),%cl
f010140b:	74 eb                	je     f01013f8 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010140d:	0f b6 00             	movzbl (%eax),%eax
f0101410:	0f b6 12             	movzbl (%edx),%edx
f0101413:	29 d0                	sub    %edx,%eax
f0101415:	eb 05                	jmp    f010141c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101417:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010141c:	5b                   	pop    %ebx
f010141d:	5d                   	pop    %ebp
f010141e:	c3                   	ret    

f010141f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010141f:	55                   	push   %ebp
f0101420:	89 e5                	mov    %esp,%ebp
f0101422:	8b 45 08             	mov    0x8(%ebp),%eax
f0101425:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101429:	eb 07                	jmp    f0101432 <strchr+0x13>
		if (*s == c)
f010142b:	38 ca                	cmp    %cl,%dl
f010142d:	74 0f                	je     f010143e <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010142f:	83 c0 01             	add    $0x1,%eax
f0101432:	0f b6 10             	movzbl (%eax),%edx
f0101435:	84 d2                	test   %dl,%dl
f0101437:	75 f2                	jne    f010142b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101439:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010143e:	5d                   	pop    %ebp
f010143f:	c3                   	ret    

f0101440 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101440:	55                   	push   %ebp
f0101441:	89 e5                	mov    %esp,%ebp
f0101443:	8b 45 08             	mov    0x8(%ebp),%eax
f0101446:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010144a:	eb 03                	jmp    f010144f <strfind+0xf>
f010144c:	83 c0 01             	add    $0x1,%eax
f010144f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101452:	38 ca                	cmp    %cl,%dl
f0101454:	74 04                	je     f010145a <strfind+0x1a>
f0101456:	84 d2                	test   %dl,%dl
f0101458:	75 f2                	jne    f010144c <strfind+0xc>
			break;
	return (char *) s;
}
f010145a:	5d                   	pop    %ebp
f010145b:	c3                   	ret    

f010145c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010145c:	55                   	push   %ebp
f010145d:	89 e5                	mov    %esp,%ebp
f010145f:	57                   	push   %edi
f0101460:	56                   	push   %esi
f0101461:	53                   	push   %ebx
f0101462:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101465:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101468:	85 c9                	test   %ecx,%ecx
f010146a:	74 36                	je     f01014a2 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010146c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101472:	75 28                	jne    f010149c <memset+0x40>
f0101474:	f6 c1 03             	test   $0x3,%cl
f0101477:	75 23                	jne    f010149c <memset+0x40>
		c &= 0xFF;
f0101479:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010147d:	89 d3                	mov    %edx,%ebx
f010147f:	c1 e3 08             	shl    $0x8,%ebx
f0101482:	89 d6                	mov    %edx,%esi
f0101484:	c1 e6 18             	shl    $0x18,%esi
f0101487:	89 d0                	mov    %edx,%eax
f0101489:	c1 e0 10             	shl    $0x10,%eax
f010148c:	09 f0                	or     %esi,%eax
f010148e:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101490:	89 d8                	mov    %ebx,%eax
f0101492:	09 d0                	or     %edx,%eax
f0101494:	c1 e9 02             	shr    $0x2,%ecx
f0101497:	fc                   	cld    
f0101498:	f3 ab                	rep stos %eax,%es:(%edi)
f010149a:	eb 06                	jmp    f01014a2 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010149c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010149f:	fc                   	cld    
f01014a0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014a2:	89 f8                	mov    %edi,%eax
f01014a4:	5b                   	pop    %ebx
f01014a5:	5e                   	pop    %esi
f01014a6:	5f                   	pop    %edi
f01014a7:	5d                   	pop    %ebp
f01014a8:	c3                   	ret    

f01014a9 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014a9:	55                   	push   %ebp
f01014aa:	89 e5                	mov    %esp,%ebp
f01014ac:	57                   	push   %edi
f01014ad:	56                   	push   %esi
f01014ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014b4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014b7:	39 c6                	cmp    %eax,%esi
f01014b9:	73 35                	jae    f01014f0 <memmove+0x47>
f01014bb:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014be:	39 d0                	cmp    %edx,%eax
f01014c0:	73 2e                	jae    f01014f0 <memmove+0x47>
		s += n;
		d += n;
f01014c2:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014c5:	89 d6                	mov    %edx,%esi
f01014c7:	09 fe                	or     %edi,%esi
f01014c9:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014cf:	75 13                	jne    f01014e4 <memmove+0x3b>
f01014d1:	f6 c1 03             	test   $0x3,%cl
f01014d4:	75 0e                	jne    f01014e4 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01014d6:	83 ef 04             	sub    $0x4,%edi
f01014d9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014dc:	c1 e9 02             	shr    $0x2,%ecx
f01014df:	fd                   	std    
f01014e0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014e2:	eb 09                	jmp    f01014ed <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014e4:	83 ef 01             	sub    $0x1,%edi
f01014e7:	8d 72 ff             	lea    -0x1(%edx),%esi
f01014ea:	fd                   	std    
f01014eb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014ed:	fc                   	cld    
f01014ee:	eb 1d                	jmp    f010150d <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014f0:	89 f2                	mov    %esi,%edx
f01014f2:	09 c2                	or     %eax,%edx
f01014f4:	f6 c2 03             	test   $0x3,%dl
f01014f7:	75 0f                	jne    f0101508 <memmove+0x5f>
f01014f9:	f6 c1 03             	test   $0x3,%cl
f01014fc:	75 0a                	jne    f0101508 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01014fe:	c1 e9 02             	shr    $0x2,%ecx
f0101501:	89 c7                	mov    %eax,%edi
f0101503:	fc                   	cld    
f0101504:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101506:	eb 05                	jmp    f010150d <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101508:	89 c7                	mov    %eax,%edi
f010150a:	fc                   	cld    
f010150b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010150d:	5e                   	pop    %esi
f010150e:	5f                   	pop    %edi
f010150f:	5d                   	pop    %ebp
f0101510:	c3                   	ret    

f0101511 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101511:	55                   	push   %ebp
f0101512:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101514:	ff 75 10             	pushl  0x10(%ebp)
f0101517:	ff 75 0c             	pushl  0xc(%ebp)
f010151a:	ff 75 08             	pushl  0x8(%ebp)
f010151d:	e8 87 ff ff ff       	call   f01014a9 <memmove>
}
f0101522:	c9                   	leave  
f0101523:	c3                   	ret    

f0101524 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101524:	55                   	push   %ebp
f0101525:	89 e5                	mov    %esp,%ebp
f0101527:	56                   	push   %esi
f0101528:	53                   	push   %ebx
f0101529:	8b 45 08             	mov    0x8(%ebp),%eax
f010152c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010152f:	89 c6                	mov    %eax,%esi
f0101531:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101534:	eb 1a                	jmp    f0101550 <memcmp+0x2c>
		if (*s1 != *s2)
f0101536:	0f b6 08             	movzbl (%eax),%ecx
f0101539:	0f b6 1a             	movzbl (%edx),%ebx
f010153c:	38 d9                	cmp    %bl,%cl
f010153e:	74 0a                	je     f010154a <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101540:	0f b6 c1             	movzbl %cl,%eax
f0101543:	0f b6 db             	movzbl %bl,%ebx
f0101546:	29 d8                	sub    %ebx,%eax
f0101548:	eb 0f                	jmp    f0101559 <memcmp+0x35>
		s1++, s2++;
f010154a:	83 c0 01             	add    $0x1,%eax
f010154d:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101550:	39 f0                	cmp    %esi,%eax
f0101552:	75 e2                	jne    f0101536 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101554:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101559:	5b                   	pop    %ebx
f010155a:	5e                   	pop    %esi
f010155b:	5d                   	pop    %ebp
f010155c:	c3                   	ret    

f010155d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010155d:	55                   	push   %ebp
f010155e:	89 e5                	mov    %esp,%ebp
f0101560:	53                   	push   %ebx
f0101561:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101564:	89 c1                	mov    %eax,%ecx
f0101566:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101569:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010156d:	eb 0a                	jmp    f0101579 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010156f:	0f b6 10             	movzbl (%eax),%edx
f0101572:	39 da                	cmp    %ebx,%edx
f0101574:	74 07                	je     f010157d <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101576:	83 c0 01             	add    $0x1,%eax
f0101579:	39 c8                	cmp    %ecx,%eax
f010157b:	72 f2                	jb     f010156f <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010157d:	5b                   	pop    %ebx
f010157e:	5d                   	pop    %ebp
f010157f:	c3                   	ret    

f0101580 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101580:	55                   	push   %ebp
f0101581:	89 e5                	mov    %esp,%ebp
f0101583:	57                   	push   %edi
f0101584:	56                   	push   %esi
f0101585:	53                   	push   %ebx
f0101586:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101589:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010158c:	eb 03                	jmp    f0101591 <strtol+0x11>
		s++;
f010158e:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101591:	0f b6 01             	movzbl (%ecx),%eax
f0101594:	3c 20                	cmp    $0x20,%al
f0101596:	74 f6                	je     f010158e <strtol+0xe>
f0101598:	3c 09                	cmp    $0x9,%al
f010159a:	74 f2                	je     f010158e <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010159c:	3c 2b                	cmp    $0x2b,%al
f010159e:	75 0a                	jne    f01015aa <strtol+0x2a>
		s++;
f01015a0:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015a3:	bf 00 00 00 00       	mov    $0x0,%edi
f01015a8:	eb 11                	jmp    f01015bb <strtol+0x3b>
f01015aa:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015af:	3c 2d                	cmp    $0x2d,%al
f01015b1:	75 08                	jne    f01015bb <strtol+0x3b>
		s++, neg = 1;
f01015b3:	83 c1 01             	add    $0x1,%ecx
f01015b6:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015bb:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015c1:	75 15                	jne    f01015d8 <strtol+0x58>
f01015c3:	80 39 30             	cmpb   $0x30,(%ecx)
f01015c6:	75 10                	jne    f01015d8 <strtol+0x58>
f01015c8:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01015cc:	75 7c                	jne    f010164a <strtol+0xca>
		s += 2, base = 16;
f01015ce:	83 c1 02             	add    $0x2,%ecx
f01015d1:	bb 10 00 00 00       	mov    $0x10,%ebx
f01015d6:	eb 16                	jmp    f01015ee <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01015d8:	85 db                	test   %ebx,%ebx
f01015da:	75 12                	jne    f01015ee <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01015dc:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015e1:	80 39 30             	cmpb   $0x30,(%ecx)
f01015e4:	75 08                	jne    f01015ee <strtol+0x6e>
		s++, base = 8;
f01015e6:	83 c1 01             	add    $0x1,%ecx
f01015e9:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01015ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01015f3:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015f6:	0f b6 11             	movzbl (%ecx),%edx
f01015f9:	8d 72 d0             	lea    -0x30(%edx),%esi
f01015fc:	89 f3                	mov    %esi,%ebx
f01015fe:	80 fb 09             	cmp    $0x9,%bl
f0101601:	77 08                	ja     f010160b <strtol+0x8b>
			dig = *s - '0';
f0101603:	0f be d2             	movsbl %dl,%edx
f0101606:	83 ea 30             	sub    $0x30,%edx
f0101609:	eb 22                	jmp    f010162d <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010160b:	8d 72 9f             	lea    -0x61(%edx),%esi
f010160e:	89 f3                	mov    %esi,%ebx
f0101610:	80 fb 19             	cmp    $0x19,%bl
f0101613:	77 08                	ja     f010161d <strtol+0x9d>
			dig = *s - 'a' + 10;
f0101615:	0f be d2             	movsbl %dl,%edx
f0101618:	83 ea 57             	sub    $0x57,%edx
f010161b:	eb 10                	jmp    f010162d <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010161d:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101620:	89 f3                	mov    %esi,%ebx
f0101622:	80 fb 19             	cmp    $0x19,%bl
f0101625:	77 16                	ja     f010163d <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101627:	0f be d2             	movsbl %dl,%edx
f010162a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010162d:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101630:	7d 0b                	jge    f010163d <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0101632:	83 c1 01             	add    $0x1,%ecx
f0101635:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101639:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010163b:	eb b9                	jmp    f01015f6 <strtol+0x76>

	if (endptr)
f010163d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101641:	74 0d                	je     f0101650 <strtol+0xd0>
		*endptr = (char *) s;
f0101643:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101646:	89 0e                	mov    %ecx,(%esi)
f0101648:	eb 06                	jmp    f0101650 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010164a:	85 db                	test   %ebx,%ebx
f010164c:	74 98                	je     f01015e6 <strtol+0x66>
f010164e:	eb 9e                	jmp    f01015ee <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101650:	89 c2                	mov    %eax,%edx
f0101652:	f7 da                	neg    %edx
f0101654:	85 ff                	test   %edi,%edi
f0101656:	0f 45 c2             	cmovne %edx,%eax
}
f0101659:	5b                   	pop    %ebx
f010165a:	5e                   	pop    %esi
f010165b:	5f                   	pop    %edi
f010165c:	5d                   	pop    %ebp
f010165d:	c3                   	ret    
f010165e:	66 90                	xchg   %ax,%ax

f0101660 <__udivdi3>:
f0101660:	55                   	push   %ebp
f0101661:	57                   	push   %edi
f0101662:	56                   	push   %esi
f0101663:	53                   	push   %ebx
f0101664:	83 ec 1c             	sub    $0x1c,%esp
f0101667:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010166b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010166f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101673:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101677:	85 f6                	test   %esi,%esi
f0101679:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010167d:	89 ca                	mov    %ecx,%edx
f010167f:	89 f8                	mov    %edi,%eax
f0101681:	75 3d                	jne    f01016c0 <__udivdi3+0x60>
f0101683:	39 cf                	cmp    %ecx,%edi
f0101685:	0f 87 c5 00 00 00    	ja     f0101750 <__udivdi3+0xf0>
f010168b:	85 ff                	test   %edi,%edi
f010168d:	89 fd                	mov    %edi,%ebp
f010168f:	75 0b                	jne    f010169c <__udivdi3+0x3c>
f0101691:	b8 01 00 00 00       	mov    $0x1,%eax
f0101696:	31 d2                	xor    %edx,%edx
f0101698:	f7 f7                	div    %edi
f010169a:	89 c5                	mov    %eax,%ebp
f010169c:	89 c8                	mov    %ecx,%eax
f010169e:	31 d2                	xor    %edx,%edx
f01016a0:	f7 f5                	div    %ebp
f01016a2:	89 c1                	mov    %eax,%ecx
f01016a4:	89 d8                	mov    %ebx,%eax
f01016a6:	89 cf                	mov    %ecx,%edi
f01016a8:	f7 f5                	div    %ebp
f01016aa:	89 c3                	mov    %eax,%ebx
f01016ac:	89 d8                	mov    %ebx,%eax
f01016ae:	89 fa                	mov    %edi,%edx
f01016b0:	83 c4 1c             	add    $0x1c,%esp
f01016b3:	5b                   	pop    %ebx
f01016b4:	5e                   	pop    %esi
f01016b5:	5f                   	pop    %edi
f01016b6:	5d                   	pop    %ebp
f01016b7:	c3                   	ret    
f01016b8:	90                   	nop
f01016b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016c0:	39 ce                	cmp    %ecx,%esi
f01016c2:	77 74                	ja     f0101738 <__udivdi3+0xd8>
f01016c4:	0f bd fe             	bsr    %esi,%edi
f01016c7:	83 f7 1f             	xor    $0x1f,%edi
f01016ca:	0f 84 98 00 00 00    	je     f0101768 <__udivdi3+0x108>
f01016d0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01016d5:	89 f9                	mov    %edi,%ecx
f01016d7:	89 c5                	mov    %eax,%ebp
f01016d9:	29 fb                	sub    %edi,%ebx
f01016db:	d3 e6                	shl    %cl,%esi
f01016dd:	89 d9                	mov    %ebx,%ecx
f01016df:	d3 ed                	shr    %cl,%ebp
f01016e1:	89 f9                	mov    %edi,%ecx
f01016e3:	d3 e0                	shl    %cl,%eax
f01016e5:	09 ee                	or     %ebp,%esi
f01016e7:	89 d9                	mov    %ebx,%ecx
f01016e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016ed:	89 d5                	mov    %edx,%ebp
f01016ef:	8b 44 24 08          	mov    0x8(%esp),%eax
f01016f3:	d3 ed                	shr    %cl,%ebp
f01016f5:	89 f9                	mov    %edi,%ecx
f01016f7:	d3 e2                	shl    %cl,%edx
f01016f9:	89 d9                	mov    %ebx,%ecx
f01016fb:	d3 e8                	shr    %cl,%eax
f01016fd:	09 c2                	or     %eax,%edx
f01016ff:	89 d0                	mov    %edx,%eax
f0101701:	89 ea                	mov    %ebp,%edx
f0101703:	f7 f6                	div    %esi
f0101705:	89 d5                	mov    %edx,%ebp
f0101707:	89 c3                	mov    %eax,%ebx
f0101709:	f7 64 24 0c          	mull   0xc(%esp)
f010170d:	39 d5                	cmp    %edx,%ebp
f010170f:	72 10                	jb     f0101721 <__udivdi3+0xc1>
f0101711:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101715:	89 f9                	mov    %edi,%ecx
f0101717:	d3 e6                	shl    %cl,%esi
f0101719:	39 c6                	cmp    %eax,%esi
f010171b:	73 07                	jae    f0101724 <__udivdi3+0xc4>
f010171d:	39 d5                	cmp    %edx,%ebp
f010171f:	75 03                	jne    f0101724 <__udivdi3+0xc4>
f0101721:	83 eb 01             	sub    $0x1,%ebx
f0101724:	31 ff                	xor    %edi,%edi
f0101726:	89 d8                	mov    %ebx,%eax
f0101728:	89 fa                	mov    %edi,%edx
f010172a:	83 c4 1c             	add    $0x1c,%esp
f010172d:	5b                   	pop    %ebx
f010172e:	5e                   	pop    %esi
f010172f:	5f                   	pop    %edi
f0101730:	5d                   	pop    %ebp
f0101731:	c3                   	ret    
f0101732:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101738:	31 ff                	xor    %edi,%edi
f010173a:	31 db                	xor    %ebx,%ebx
f010173c:	89 d8                	mov    %ebx,%eax
f010173e:	89 fa                	mov    %edi,%edx
f0101740:	83 c4 1c             	add    $0x1c,%esp
f0101743:	5b                   	pop    %ebx
f0101744:	5e                   	pop    %esi
f0101745:	5f                   	pop    %edi
f0101746:	5d                   	pop    %ebp
f0101747:	c3                   	ret    
f0101748:	90                   	nop
f0101749:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101750:	89 d8                	mov    %ebx,%eax
f0101752:	f7 f7                	div    %edi
f0101754:	31 ff                	xor    %edi,%edi
f0101756:	89 c3                	mov    %eax,%ebx
f0101758:	89 d8                	mov    %ebx,%eax
f010175a:	89 fa                	mov    %edi,%edx
f010175c:	83 c4 1c             	add    $0x1c,%esp
f010175f:	5b                   	pop    %ebx
f0101760:	5e                   	pop    %esi
f0101761:	5f                   	pop    %edi
f0101762:	5d                   	pop    %ebp
f0101763:	c3                   	ret    
f0101764:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101768:	39 ce                	cmp    %ecx,%esi
f010176a:	72 0c                	jb     f0101778 <__udivdi3+0x118>
f010176c:	31 db                	xor    %ebx,%ebx
f010176e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101772:	0f 87 34 ff ff ff    	ja     f01016ac <__udivdi3+0x4c>
f0101778:	bb 01 00 00 00       	mov    $0x1,%ebx
f010177d:	e9 2a ff ff ff       	jmp    f01016ac <__udivdi3+0x4c>
f0101782:	66 90                	xchg   %ax,%ax
f0101784:	66 90                	xchg   %ax,%ax
f0101786:	66 90                	xchg   %ax,%ax
f0101788:	66 90                	xchg   %ax,%ax
f010178a:	66 90                	xchg   %ax,%ax
f010178c:	66 90                	xchg   %ax,%ax
f010178e:	66 90                	xchg   %ax,%ax

f0101790 <__umoddi3>:
f0101790:	55                   	push   %ebp
f0101791:	57                   	push   %edi
f0101792:	56                   	push   %esi
f0101793:	53                   	push   %ebx
f0101794:	83 ec 1c             	sub    $0x1c,%esp
f0101797:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010179b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010179f:	8b 74 24 34          	mov    0x34(%esp),%esi
f01017a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01017a7:	85 d2                	test   %edx,%edx
f01017a9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01017ad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017b1:	89 f3                	mov    %esi,%ebx
f01017b3:	89 3c 24             	mov    %edi,(%esp)
f01017b6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01017ba:	75 1c                	jne    f01017d8 <__umoddi3+0x48>
f01017bc:	39 f7                	cmp    %esi,%edi
f01017be:	76 50                	jbe    f0101810 <__umoddi3+0x80>
f01017c0:	89 c8                	mov    %ecx,%eax
f01017c2:	89 f2                	mov    %esi,%edx
f01017c4:	f7 f7                	div    %edi
f01017c6:	89 d0                	mov    %edx,%eax
f01017c8:	31 d2                	xor    %edx,%edx
f01017ca:	83 c4 1c             	add    $0x1c,%esp
f01017cd:	5b                   	pop    %ebx
f01017ce:	5e                   	pop    %esi
f01017cf:	5f                   	pop    %edi
f01017d0:	5d                   	pop    %ebp
f01017d1:	c3                   	ret    
f01017d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017d8:	39 f2                	cmp    %esi,%edx
f01017da:	89 d0                	mov    %edx,%eax
f01017dc:	77 52                	ja     f0101830 <__umoddi3+0xa0>
f01017de:	0f bd ea             	bsr    %edx,%ebp
f01017e1:	83 f5 1f             	xor    $0x1f,%ebp
f01017e4:	75 5a                	jne    f0101840 <__umoddi3+0xb0>
f01017e6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01017ea:	0f 82 e0 00 00 00    	jb     f01018d0 <__umoddi3+0x140>
f01017f0:	39 0c 24             	cmp    %ecx,(%esp)
f01017f3:	0f 86 d7 00 00 00    	jbe    f01018d0 <__umoddi3+0x140>
f01017f9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017fd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101801:	83 c4 1c             	add    $0x1c,%esp
f0101804:	5b                   	pop    %ebx
f0101805:	5e                   	pop    %esi
f0101806:	5f                   	pop    %edi
f0101807:	5d                   	pop    %ebp
f0101808:	c3                   	ret    
f0101809:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101810:	85 ff                	test   %edi,%edi
f0101812:	89 fd                	mov    %edi,%ebp
f0101814:	75 0b                	jne    f0101821 <__umoddi3+0x91>
f0101816:	b8 01 00 00 00       	mov    $0x1,%eax
f010181b:	31 d2                	xor    %edx,%edx
f010181d:	f7 f7                	div    %edi
f010181f:	89 c5                	mov    %eax,%ebp
f0101821:	89 f0                	mov    %esi,%eax
f0101823:	31 d2                	xor    %edx,%edx
f0101825:	f7 f5                	div    %ebp
f0101827:	89 c8                	mov    %ecx,%eax
f0101829:	f7 f5                	div    %ebp
f010182b:	89 d0                	mov    %edx,%eax
f010182d:	eb 99                	jmp    f01017c8 <__umoddi3+0x38>
f010182f:	90                   	nop
f0101830:	89 c8                	mov    %ecx,%eax
f0101832:	89 f2                	mov    %esi,%edx
f0101834:	83 c4 1c             	add    $0x1c,%esp
f0101837:	5b                   	pop    %ebx
f0101838:	5e                   	pop    %esi
f0101839:	5f                   	pop    %edi
f010183a:	5d                   	pop    %ebp
f010183b:	c3                   	ret    
f010183c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101840:	8b 34 24             	mov    (%esp),%esi
f0101843:	bf 20 00 00 00       	mov    $0x20,%edi
f0101848:	89 e9                	mov    %ebp,%ecx
f010184a:	29 ef                	sub    %ebp,%edi
f010184c:	d3 e0                	shl    %cl,%eax
f010184e:	89 f9                	mov    %edi,%ecx
f0101850:	89 f2                	mov    %esi,%edx
f0101852:	d3 ea                	shr    %cl,%edx
f0101854:	89 e9                	mov    %ebp,%ecx
f0101856:	09 c2                	or     %eax,%edx
f0101858:	89 d8                	mov    %ebx,%eax
f010185a:	89 14 24             	mov    %edx,(%esp)
f010185d:	89 f2                	mov    %esi,%edx
f010185f:	d3 e2                	shl    %cl,%edx
f0101861:	89 f9                	mov    %edi,%ecx
f0101863:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101867:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010186b:	d3 e8                	shr    %cl,%eax
f010186d:	89 e9                	mov    %ebp,%ecx
f010186f:	89 c6                	mov    %eax,%esi
f0101871:	d3 e3                	shl    %cl,%ebx
f0101873:	89 f9                	mov    %edi,%ecx
f0101875:	89 d0                	mov    %edx,%eax
f0101877:	d3 e8                	shr    %cl,%eax
f0101879:	89 e9                	mov    %ebp,%ecx
f010187b:	09 d8                	or     %ebx,%eax
f010187d:	89 d3                	mov    %edx,%ebx
f010187f:	89 f2                	mov    %esi,%edx
f0101881:	f7 34 24             	divl   (%esp)
f0101884:	89 d6                	mov    %edx,%esi
f0101886:	d3 e3                	shl    %cl,%ebx
f0101888:	f7 64 24 04          	mull   0x4(%esp)
f010188c:	39 d6                	cmp    %edx,%esi
f010188e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101892:	89 d1                	mov    %edx,%ecx
f0101894:	89 c3                	mov    %eax,%ebx
f0101896:	72 08                	jb     f01018a0 <__umoddi3+0x110>
f0101898:	75 11                	jne    f01018ab <__umoddi3+0x11b>
f010189a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010189e:	73 0b                	jae    f01018ab <__umoddi3+0x11b>
f01018a0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01018a4:	1b 14 24             	sbb    (%esp),%edx
f01018a7:	89 d1                	mov    %edx,%ecx
f01018a9:	89 c3                	mov    %eax,%ebx
f01018ab:	8b 54 24 08          	mov    0x8(%esp),%edx
f01018af:	29 da                	sub    %ebx,%edx
f01018b1:	19 ce                	sbb    %ecx,%esi
f01018b3:	89 f9                	mov    %edi,%ecx
f01018b5:	89 f0                	mov    %esi,%eax
f01018b7:	d3 e0                	shl    %cl,%eax
f01018b9:	89 e9                	mov    %ebp,%ecx
f01018bb:	d3 ea                	shr    %cl,%edx
f01018bd:	89 e9                	mov    %ebp,%ecx
f01018bf:	d3 ee                	shr    %cl,%esi
f01018c1:	09 d0                	or     %edx,%eax
f01018c3:	89 f2                	mov    %esi,%edx
f01018c5:	83 c4 1c             	add    $0x1c,%esp
f01018c8:	5b                   	pop    %ebx
f01018c9:	5e                   	pop    %esi
f01018ca:	5f                   	pop    %edi
f01018cb:	5d                   	pop    %ebp
f01018cc:	c3                   	ret    
f01018cd:	8d 76 00             	lea    0x0(%esi),%esi
f01018d0:	29 f9                	sub    %edi,%ecx
f01018d2:	19 d6                	sbb    %edx,%esi
f01018d4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01018d8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018dc:	e9 18 ff ff ff       	jmp    f01017f9 <__umoddi3+0x69>
