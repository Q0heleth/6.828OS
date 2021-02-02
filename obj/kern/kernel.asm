
obj/kern/kernel：     文件格式 elf32-i386


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
f010000b:	e4 66                	in     $0x66,%al

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
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

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
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 20 1a 10 f0 	movl   $0xf0101a20,(%esp)
f0100055:	e8 bf 09 00 00       	call   f0100a19 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 54 07 00 00       	call   f01007db <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 3c 1a 10 f0 	movl   $0xf0101a3c,(%esp)
f0100092:	e8 82 09 00 00       	call   f0100a19 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 40 29 11 f0       	mov    $0xf0112940,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 c2 14 00 00       	call   f0101587 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 c5 04 00 00       	call   f010058f <cons_init>
	{
        int x = 1, y = 3, z = 4;
        Lab1:
        cprintf("x %d, y %x, z %d\n", x, y, z);
f01000ca:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01000d1:	00 
f01000d2:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
f01000d9:	00 
f01000da:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01000e1:	00 
f01000e2:	c7 04 24 57 1a 10 f0 	movl   $0xf0101a57,(%esp)
f01000e9:	e8 2b 09 00 00       	call   f0100a19 <cprintf>
	}
	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ee:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000f5:	00 
f01000f6:	c7 04 24 69 1a 10 f0 	movl   $0xf0101a69,(%esp)
f01000fd:	e8 17 09 00 00       	call   f0100a19 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f0100102:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f0100109:	e8 32 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010010e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100115:	e8 86 07 00 00       	call   f01008a0 <monitor>
f010011a:	eb f2                	jmp    f010010e <i386_init+0x71>

f010011c <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp
f010011f:	56                   	push   %esi
f0100120:	53                   	push   %ebx
f0100121:	83 ec 10             	sub    $0x10,%esp
f0100124:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100127:	83 3d 44 29 11 f0 00 	cmpl   $0x0,0xf0112944
f010012e:	75 3d                	jne    f010016d <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100130:	89 35 44 29 11 f0    	mov    %esi,0xf0112944

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100136:	fa                   	cli    
f0100137:	fc                   	cld    

	va_start(ap, fmt);
f0100138:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f010013b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010013e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100142:	8b 45 08             	mov    0x8(%ebp),%eax
f0100145:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100149:	c7 04 24 84 1a 10 f0 	movl   $0xf0101a84,(%esp)
f0100150:	e8 c4 08 00 00       	call   f0100a19 <cprintf>
	vcprintf(fmt, ap);
f0100155:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100159:	89 34 24             	mov    %esi,(%esp)
f010015c:	e8 85 08 00 00       	call   f01009e6 <vcprintf>
	cprintf("\n");
f0100161:	c7 04 24 c0 1a 10 f0 	movl   $0xf0101ac0,(%esp)
f0100168:	e8 ac 08 00 00       	call   f0100a19 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010016d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100174:	e8 27 07 00 00       	call   f01008a0 <monitor>
f0100179:	eb f2                	jmp    f010016d <_panic+0x51>

f010017b <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010017b:	55                   	push   %ebp
f010017c:	89 e5                	mov    %esp,%ebp
f010017e:	53                   	push   %ebx
f010017f:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100182:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100185:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100188:	89 44 24 08          	mov    %eax,0x8(%esp)
f010018c:	8b 45 08             	mov    0x8(%ebp),%eax
f010018f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100193:	c7 04 24 9c 1a 10 f0 	movl   $0xf0101a9c,(%esp)
f010019a:	e8 7a 08 00 00       	call   f0100a19 <cprintf>
	vcprintf(fmt, ap);
f010019f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01001a3:	8b 45 10             	mov    0x10(%ebp),%eax
f01001a6:	89 04 24             	mov    %eax,(%esp)
f01001a9:	e8 38 08 00 00       	call   f01009e6 <vcprintf>
	cprintf("\n");
f01001ae:	c7 04 24 c0 1a 10 f0 	movl   $0xf0101ac0,(%esp)
f01001b5:	e8 5f 08 00 00       	call   f0100a19 <cprintf>
	va_end(ap);
}
f01001ba:	83 c4 14             	add    $0x14,%esp
f01001bd:	5b                   	pop    %ebx
f01001be:	5d                   	pop    %ebp
f01001bf:	c3                   	ret    

f01001c0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001c0:	55                   	push   %ebp
f01001c1:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001c3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001c8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001c9:	a8 01                	test   $0x1,%al
f01001cb:	74 08                	je     f01001d5 <serial_proc_data+0x15>
f01001cd:	b2 f8                	mov    $0xf8,%dl
f01001cf:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	eb 05                	jmp    f01001da <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001da:	5d                   	pop    %ebp
f01001db:	c3                   	ret    

f01001dc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001dc:	55                   	push   %ebp
f01001dd:	89 e5                	mov    %esp,%ebp
f01001df:	53                   	push   %ebx
f01001e0:	83 ec 04             	sub    $0x4,%esp
f01001e3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001e5:	eb 2a                	jmp    f0100211 <cons_intr+0x35>
		if (c == 0)
f01001e7:	85 d2                	test   %edx,%edx
f01001e9:	74 26                	je     f0100211 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001eb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001f0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001f3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001f9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001ff:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100205:	75 0a                	jne    f0100211 <cons_intr+0x35>
			cons.wpos = 0;
f0100207:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f010020e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100211:	ff d3                	call   *%ebx
f0100213:	89 c2                	mov    %eax,%edx
f0100215:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100218:	75 cd                	jne    f01001e7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010021a:	83 c4 04             	add    $0x4,%esp
f010021d:	5b                   	pop    %ebx
f010021e:	5d                   	pop    %ebp
f010021f:	c3                   	ret    

f0100220 <kbd_proc_data>:
f0100220:	ba 64 00 00 00       	mov    $0x64,%edx
f0100225:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100226:	a8 01                	test   $0x1,%al
f0100228:	0f 84 f7 00 00 00    	je     f0100325 <kbd_proc_data+0x105>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010022e:	a8 20                	test   $0x20,%al
f0100230:	0f 85 f5 00 00 00    	jne    f010032b <kbd_proc_data+0x10b>
f0100236:	b2 60                	mov    $0x60,%dl
f0100238:	ec                   	in     (%dx),%al
f0100239:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010023b:	3c e0                	cmp    $0xe0,%al
f010023d:	75 0d                	jne    f010024c <kbd_proc_data+0x2c>
		// E0 escape character
		shift |= E0ESC;
f010023f:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100246:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010024b:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010024c:	55                   	push   %ebp
f010024d:	89 e5                	mov    %esp,%ebp
f010024f:	53                   	push   %ebx
f0100250:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100253:	84 c0                	test   %al,%al
f0100255:	79 37                	jns    f010028e <kbd_proc_data+0x6e>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100257:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010025d:	89 cb                	mov    %ecx,%ebx
f010025f:	83 e3 40             	and    $0x40,%ebx
f0100262:	83 e0 7f             	and    $0x7f,%eax
f0100265:	85 db                	test   %ebx,%ebx
f0100267:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010026a:	0f b6 d2             	movzbl %dl,%edx
f010026d:	0f b6 82 00 1c 10 f0 	movzbl -0xfefe400(%edx),%eax
f0100274:	83 c8 40             	or     $0x40,%eax
f0100277:	0f b6 c0             	movzbl %al,%eax
f010027a:	f7 d0                	not    %eax
f010027c:	21 c1                	and    %eax,%ecx
f010027e:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f0100284:	b8 00 00 00 00       	mov    $0x0,%eax
f0100289:	e9 a3 00 00 00       	jmp    f0100331 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010028e:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100294:	f6 c1 40             	test   $0x40,%cl
f0100297:	74 0e                	je     f01002a7 <kbd_proc_data+0x87>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100299:	83 c8 80             	or     $0xffffff80,%eax
f010029c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010029e:	83 e1 bf             	and    $0xffffffbf,%ecx
f01002a1:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f01002a7:	0f b6 d2             	movzbl %dl,%edx
f01002aa:	0f b6 82 00 1c 10 f0 	movzbl -0xfefe400(%edx),%eax
f01002b1:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f01002b7:	0f b6 8a 00 1b 10 f0 	movzbl -0xfefe500(%edx),%ecx
f01002be:	31 c8                	xor    %ecx,%eax
f01002c0:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f01002c5:	89 c1                	mov    %eax,%ecx
f01002c7:	83 e1 03             	and    $0x3,%ecx
f01002ca:	8b 0c 8d e0 1a 10 f0 	mov    -0xfefe520(,%ecx,4),%ecx
f01002d1:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002d5:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002d8:	a8 08                	test   $0x8,%al
f01002da:	74 1b                	je     f01002f7 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f01002dc:	89 da                	mov    %ebx,%edx
f01002de:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002e1:	83 f9 19             	cmp    $0x19,%ecx
f01002e4:	77 05                	ja     f01002eb <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f01002e6:	83 eb 20             	sub    $0x20,%ebx
f01002e9:	eb 0c                	jmp    f01002f7 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f01002eb:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002ee:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002f1:	83 fa 19             	cmp    $0x19,%edx
f01002f4:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002f7:	f7 d0                	not    %eax
f01002f9:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002fb:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002fd:	f6 c2 06             	test   $0x6,%dl
f0100300:	75 2f                	jne    f0100331 <kbd_proc_data+0x111>
f0100302:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100308:	75 27                	jne    f0100331 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f010030a:	c7 04 24 b6 1a 10 f0 	movl   $0xf0101ab6,(%esp)
f0100311:	e8 03 07 00 00       	call   f0100a19 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100316:	ba 92 00 00 00       	mov    $0x92,%edx
f010031b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100320:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100321:	89 d8                	mov    %ebx,%eax
f0100323:	eb 0c                	jmp    f0100331 <kbd_proc_data+0x111>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100325:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010032a:	c3                   	ret    
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010032b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100330:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100331:	83 c4 14             	add    $0x14,%esp
f0100334:	5b                   	pop    %ebx
f0100335:	5d                   	pop    %ebp
f0100336:	c3                   	ret    

f0100337 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100337:	55                   	push   %ebp
f0100338:	89 e5                	mov    %esp,%ebp
f010033a:	57                   	push   %edi
f010033b:	56                   	push   %esi
f010033c:	53                   	push   %ebx
f010033d:	83 ec 1c             	sub    $0x1c,%esp
f0100340:	89 c7                	mov    %eax,%edi
f0100342:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100347:	be fd 03 00 00       	mov    $0x3fd,%esi
f010034c:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100351:	eb 06                	jmp    f0100359 <cons_putc+0x22>
f0100353:	89 ca                	mov    %ecx,%edx
f0100355:	ec                   	in     (%dx),%al
f0100356:	ec                   	in     (%dx),%al
f0100357:	ec                   	in     (%dx),%al
f0100358:	ec                   	in     (%dx),%al
f0100359:	89 f2                	mov    %esi,%edx
f010035b:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010035c:	a8 20                	test   $0x20,%al
f010035e:	75 05                	jne    f0100365 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100360:	83 eb 01             	sub    $0x1,%ebx
f0100363:	75 ee                	jne    f0100353 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100365:	89 f8                	mov    %edi,%eax
f0100367:	0f b6 c0             	movzbl %al,%eax
f010036a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010036d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100372:	ee                   	out    %al,(%dx)
f0100373:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100378:	be 79 03 00 00       	mov    $0x379,%esi
f010037d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100382:	eb 06                	jmp    f010038a <cons_putc+0x53>
f0100384:	89 ca                	mov    %ecx,%edx
f0100386:	ec                   	in     (%dx),%al
f0100387:	ec                   	in     (%dx),%al
f0100388:	ec                   	in     (%dx),%al
f0100389:	ec                   	in     (%dx),%al
f010038a:	89 f2                	mov    %esi,%edx
f010038c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010038d:	84 c0                	test   %al,%al
f010038f:	78 05                	js     f0100396 <cons_putc+0x5f>
f0100391:	83 eb 01             	sub    $0x1,%ebx
f0100394:	75 ee                	jne    f0100384 <cons_putc+0x4d>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100396:	ba 78 03 00 00       	mov    $0x378,%edx
f010039b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010039f:	ee                   	out    %al,(%dx)
f01003a0:	b2 7a                	mov    $0x7a,%dl
f01003a2:	b8 0d 00 00 00       	mov    $0xd,%eax
f01003a7:	ee                   	out    %al,(%dx)
f01003a8:	b8 08 00 00 00       	mov    $0x8,%eax
f01003ad:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01003ae:	89 fa                	mov    %edi,%edx
f01003b0:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003b6:	89 f8                	mov    %edi,%eax
f01003b8:	80 cc 07             	or     $0x7,%ah
f01003bb:	85 d2                	test   %edx,%edx
f01003bd:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01003c0:	89 f8                	mov    %edi,%eax
f01003c2:	0f b6 c0             	movzbl %al,%eax
f01003c5:	83 f8 09             	cmp    $0x9,%eax
f01003c8:	74 78                	je     f0100442 <cons_putc+0x10b>
f01003ca:	83 f8 09             	cmp    $0x9,%eax
f01003cd:	7f 0a                	jg     f01003d9 <cons_putc+0xa2>
f01003cf:	83 f8 08             	cmp    $0x8,%eax
f01003d2:	74 18                	je     f01003ec <cons_putc+0xb5>
f01003d4:	e9 9d 00 00 00       	jmp    f0100476 <cons_putc+0x13f>
f01003d9:	83 f8 0a             	cmp    $0xa,%eax
f01003dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01003e0:	74 3a                	je     f010041c <cons_putc+0xe5>
f01003e2:	83 f8 0d             	cmp    $0xd,%eax
f01003e5:	74 3d                	je     f0100424 <cons_putc+0xed>
f01003e7:	e9 8a 00 00 00       	jmp    f0100476 <cons_putc+0x13f>
	case '\b':
		if (crt_pos > 0) {
f01003ec:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003f3:	66 85 c0             	test   %ax,%ax
f01003f6:	0f 84 e5 00 00 00    	je     f01004e1 <cons_putc+0x1aa>
			crt_pos--;
f01003fc:	83 e8 01             	sub    $0x1,%eax
f01003ff:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100405:	0f b7 c0             	movzwl %ax,%eax
f0100408:	66 81 e7 00 ff       	and    $0xff00,%di
f010040d:	83 cf 20             	or     $0x20,%edi
f0100410:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100416:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010041a:	eb 78                	jmp    f0100494 <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010041c:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f0100423:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100424:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010042b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100431:	c1 e8 16             	shr    $0x16,%eax
f0100434:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100437:	c1 e0 04             	shl    $0x4,%eax
f010043a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100440:	eb 52                	jmp    f0100494 <cons_putc+0x15d>
		break;
	case '\t':
		cons_putc(' ');
f0100442:	b8 20 00 00 00       	mov    $0x20,%eax
f0100447:	e8 eb fe ff ff       	call   f0100337 <cons_putc>
		cons_putc(' ');
f010044c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100451:	e8 e1 fe ff ff       	call   f0100337 <cons_putc>
		cons_putc(' ');
f0100456:	b8 20 00 00 00       	mov    $0x20,%eax
f010045b:	e8 d7 fe ff ff       	call   f0100337 <cons_putc>
		cons_putc(' ');
f0100460:	b8 20 00 00 00       	mov    $0x20,%eax
f0100465:	e8 cd fe ff ff       	call   f0100337 <cons_putc>
		cons_putc(' ');
f010046a:	b8 20 00 00 00       	mov    $0x20,%eax
f010046f:	e8 c3 fe ff ff       	call   f0100337 <cons_putc>
f0100474:	eb 1e                	jmp    f0100494 <cons_putc+0x15d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100476:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010047d:	8d 50 01             	lea    0x1(%eax),%edx
f0100480:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100487:	0f b7 c0             	movzwl %ax,%eax
f010048a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100490:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100494:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010049b:	cf 07 
f010049d:	76 42                	jbe    f01004e1 <cons_putc+0x1aa>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010049f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f01004a4:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01004ab:	00 
f01004ac:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004b2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01004b6:	89 04 24             	mov    %eax,(%esp)
f01004b9:	e8 16 11 00 00       	call   f01015d4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01004be:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004c4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004c9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004cf:	83 c0 01             	add    $0x1,%eax
f01004d2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004d7:	75 f0                	jne    f01004c9 <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004d9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004e0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004e1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004e7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004ec:	89 ca                	mov    %ecx,%edx
f01004ee:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004ef:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004f6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004f9:	89 d8                	mov    %ebx,%eax
f01004fb:	66 c1 e8 08          	shr    $0x8,%ax
f01004ff:	89 f2                	mov    %esi,%edx
f0100501:	ee                   	out    %al,(%dx)
f0100502:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100507:	89 ca                	mov    %ecx,%edx
f0100509:	ee                   	out    %al,(%dx)
f010050a:	89 d8                	mov    %ebx,%eax
f010050c:	89 f2                	mov    %esi,%edx
f010050e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010050f:	83 c4 1c             	add    $0x1c,%esp
f0100512:	5b                   	pop    %ebx
f0100513:	5e                   	pop    %esi
f0100514:	5f                   	pop    %edi
f0100515:	5d                   	pop    %ebp
f0100516:	c3                   	ret    

f0100517 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100517:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f010051e:	74 11                	je     f0100531 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100520:	55                   	push   %ebp
f0100521:	89 e5                	mov    %esp,%ebp
f0100523:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100526:	b8 c0 01 10 f0       	mov    $0xf01001c0,%eax
f010052b:	e8 ac fc ff ff       	call   f01001dc <cons_intr>
}
f0100530:	c9                   	leave  
f0100531:	f3 c3                	repz ret 

f0100533 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100533:	55                   	push   %ebp
f0100534:	89 e5                	mov    %esp,%ebp
f0100536:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100539:	b8 20 02 10 f0       	mov    $0xf0100220,%eax
f010053e:	e8 99 fc ff ff       	call   f01001dc <cons_intr>
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010054b:	e8 c7 ff ff ff       	call   f0100517 <serial_intr>
	kbd_intr();
f0100550:	e8 de ff ff ff       	call   f0100533 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100555:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010055a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100560:	74 26                	je     f0100588 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100562:	8d 50 01             	lea    0x1(%eax),%edx
f0100565:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010056b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100572:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100574:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010057a:	75 11                	jne    f010058d <cons_getc+0x48>
			cons.rpos = 0;
f010057c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100583:	00 00 00 
f0100586:	eb 05                	jmp    f010058d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100588:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010058d:	c9                   	leave  
f010058e:	c3                   	ret    

f010058f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010058f:	55                   	push   %ebp
f0100590:	89 e5                	mov    %esp,%ebp
f0100592:	57                   	push   %edi
f0100593:	56                   	push   %esi
f0100594:	53                   	push   %ebx
f0100595:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100598:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010059f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005a6:	5a a5 
	if (*cp != 0xA55A) {
f01005a8:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005af:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005b3:	74 11                	je     f01005c6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01005b5:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f01005bc:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005bf:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005c4:	eb 16                	jmp    f01005dc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005c6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005cd:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005d4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005d7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005dc:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005e2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005e7:	89 ca                	mov    %ecx,%edx
f01005e9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ea:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ed:	89 da                	mov    %ebx,%edx
f01005ef:	ec                   	in     (%dx),%al
f01005f0:	0f b6 f0             	movzbl %al,%esi
f01005f3:	c1 e6 08             	shl    $0x8,%esi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005fb:	89 ca                	mov    %ecx,%edx
f01005fd:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005fe:	89 da                	mov    %ebx,%edx
f0100600:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100601:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100607:	0f b6 d8             	movzbl %al,%ebx
f010060a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010060c:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100613:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100618:	b8 00 00 00 00       	mov    $0x0,%eax
f010061d:	89 f2                	mov    %esi,%edx
f010061f:	ee                   	out    %al,(%dx)
f0100620:	b2 fb                	mov    $0xfb,%dl
f0100622:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100627:	ee                   	out    %al,(%dx)
f0100628:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010062d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100632:	89 da                	mov    %ebx,%edx
f0100634:	ee                   	out    %al,(%dx)
f0100635:	b2 f9                	mov    $0xf9,%dl
f0100637:	b8 00 00 00 00       	mov    $0x0,%eax
f010063c:	ee                   	out    %al,(%dx)
f010063d:	b2 fb                	mov    $0xfb,%dl
f010063f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100644:	ee                   	out    %al,(%dx)
f0100645:	b2 fc                	mov    $0xfc,%dl
f0100647:	b8 00 00 00 00       	mov    $0x0,%eax
f010064c:	ee                   	out    %al,(%dx)
f010064d:	b2 f9                	mov    $0xf9,%dl
f010064f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100654:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100655:	b2 fd                	mov    $0xfd,%dl
f0100657:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100658:	3c ff                	cmp    $0xff,%al
f010065a:	0f 95 c1             	setne  %cl
f010065d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100663:	89 f2                	mov    %esi,%edx
f0100665:	ec                   	in     (%dx),%al
f0100666:	89 da                	mov    %ebx,%edx
f0100668:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100669:	84 c9                	test   %cl,%cl
f010066b:	75 0c                	jne    f0100679 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010066d:	c7 04 24 c2 1a 10 f0 	movl   $0xf0101ac2,(%esp)
f0100674:	e8 a0 03 00 00       	call   f0100a19 <cprintf>
}
f0100679:	83 c4 1c             	add    $0x1c,%esp
f010067c:	5b                   	pop    %ebx
f010067d:	5e                   	pop    %esi
f010067e:	5f                   	pop    %edi
f010067f:	5d                   	pop    %ebp
f0100680:	c3                   	ret    

f0100681 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100681:	55                   	push   %ebp
f0100682:	89 e5                	mov    %esp,%ebp
f0100684:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100687:	8b 45 08             	mov    0x8(%ebp),%eax
f010068a:	e8 a8 fc ff ff       	call   f0100337 <cons_putc>
}
f010068f:	c9                   	leave  
f0100690:	c3                   	ret    

f0100691 <getchar>:

int
getchar(void)
{
f0100691:	55                   	push   %ebp
f0100692:	89 e5                	mov    %esp,%ebp
f0100694:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100697:	e8 a9 fe ff ff       	call   f0100545 <cons_getc>
f010069c:	85 c0                	test   %eax,%eax
f010069e:	74 f7                	je     f0100697 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006a0:	c9                   	leave  
f01006a1:	c3                   	ret    

f01006a2 <iscons>:

int
iscons(int fdnum)
{
f01006a2:	55                   	push   %ebp
f01006a3:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006a5:	b8 01 00 00 00       	mov    $0x1,%eax
f01006aa:	5d                   	pop    %ebp
f01006ab:	c3                   	ret    
f01006ac:	66 90                	xchg   %ax,%ax
f01006ae:	66 90                	xchg   %ax,%ax

f01006b0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006b0:	55                   	push   %ebp
f01006b1:	89 e5                	mov    %esp,%ebp
f01006b3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006b6:	c7 44 24 08 00 1d 10 	movl   $0xf0101d00,0x8(%esp)
f01006bd:	f0 
f01006be:	c7 44 24 04 1e 1d 10 	movl   $0xf0101d1e,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 23 1d 10 f0 	movl   $0xf0101d23,(%esp)
f01006cd:	e8 47 03 00 00       	call   f0100a19 <cprintf>
f01006d2:	c7 44 24 08 d4 1d 10 	movl   $0xf0101dd4,0x8(%esp)
f01006d9:	f0 
f01006da:	c7 44 24 04 2c 1d 10 	movl   $0xf0101d2c,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 23 1d 10 f0 	movl   $0xf0101d23,(%esp)
f01006e9:	e8 2b 03 00 00       	call   f0100a19 <cprintf>
f01006ee:	c7 44 24 08 35 1d 10 	movl   $0xf0101d35,0x8(%esp)
f01006f5:	f0 
f01006f6:	c7 44 24 04 3d 1d 10 	movl   $0xf0101d3d,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 23 1d 10 f0 	movl   $0xf0101d23,(%esp)
f0100705:	e8 0f 03 00 00       	call   f0100a19 <cprintf>
	return 0;
}
f010070a:	b8 00 00 00 00       	mov    $0x0,%eax
f010070f:	c9                   	leave  
f0100710:	c3                   	ret    

f0100711 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100711:	55                   	push   %ebp
f0100712:	89 e5                	mov    %esp,%ebp
f0100714:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100717:	c7 04 24 47 1d 10 f0 	movl   $0xf0101d47,(%esp)
f010071e:	e8 f6 02 00 00       	call   f0100a19 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100723:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010072a:	00 
f010072b:	c7 04 24 fc 1d 10 f0 	movl   $0xf0101dfc,(%esp)
f0100732:	e8 e2 02 00 00       	call   f0100a19 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100737:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010073e:	00 
f010073f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100746:	f0 
f0100747:	c7 04 24 24 1e 10 f0 	movl   $0xf0101e24,(%esp)
f010074e:	e8 c6 02 00 00       	call   f0100a19 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100753:	c7 44 24 08 17 1a 10 	movl   $0x101a17,0x8(%esp)
f010075a:	00 
f010075b:	c7 44 24 04 17 1a 10 	movl   $0xf0101a17,0x4(%esp)
f0100762:	f0 
f0100763:	c7 04 24 48 1e 10 f0 	movl   $0xf0101e48,(%esp)
f010076a:	e8 aa 02 00 00       	call   f0100a19 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010076f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100776:	00 
f0100777:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010077e:	f0 
f010077f:	c7 04 24 6c 1e 10 f0 	movl   $0xf0101e6c,(%esp)
f0100786:	e8 8e 02 00 00       	call   f0100a19 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010078b:	c7 44 24 08 40 29 11 	movl   $0x112940,0x8(%esp)
f0100792:	00 
f0100793:	c7 44 24 04 40 29 11 	movl   $0xf0112940,0x4(%esp)
f010079a:	f0 
f010079b:	c7 04 24 90 1e 10 f0 	movl   $0xf0101e90,(%esp)
f01007a2:	e8 72 02 00 00       	call   f0100a19 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01007a7:	b8 3f 2d 11 f0       	mov    $0xf0112d3f,%eax
f01007ac:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01007b1:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007b6:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01007bc:	85 c0                	test   %eax,%eax
f01007be:	0f 48 c2             	cmovs  %edx,%eax
f01007c1:	c1 f8 0a             	sar    $0xa,%eax
f01007c4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007c8:	c7 04 24 b4 1e 10 f0 	movl   $0xf0101eb4,(%esp)
f01007cf:	e8 45 02 00 00       	call   f0100a19 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01007d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d9:	c9                   	leave  
f01007da:	c3                   	ret    

f01007db <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007db:	55                   	push   %ebp
f01007dc:	89 e5                	mov    %esp,%ebp
f01007de:	57                   	push   %edi
f01007df:	56                   	push   %esi
f01007e0:	53                   	push   %ebx
f01007e1:	83 ec 4c             	sub    $0x4c,%esp
	// Your code here.
	cprintf("Stack backtrace:\n");
f01007e4:	c7 04 24 60 1d 10 f0 	movl   $0xf0101d60,(%esp)
f01007eb:	e8 29 02 00 00       	call   f0100a19 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01007f0:	89 eb                	mov    %ebp,%ebx
	while (ebp != 0) {
        p = (uint32_t *)ebp;
	struct Eipdebuginfo info;
        cprintf("  ebp %x  eip %x  args %08x %08x %08x %08x %08x\n",ebp,p[1],p[2],p[3],p[4],p[5],p[6]);
        ebp = p[0];
 	int ret = debuginfo_eip((uintptr_t)p[1],&info);
f01007f2:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	uint32_t ebp ,*p;
	ebp = read_ebp();
	while (ebp != 0) {
f01007f5:	e9 91 00 00 00       	jmp    f010088b <mon_backtrace+0xb0>
        p = (uint32_t *)ebp;
f01007fa:	89 de                	mov    %ebx,%esi
	struct Eipdebuginfo info;
        cprintf("  ebp %x  eip %x  args %08x %08x %08x %08x %08x\n",ebp,p[1],p[2],p[3],p[4],p[5],p[6]);
f01007fc:	8b 43 18             	mov    0x18(%ebx),%eax
f01007ff:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100803:	8b 43 14             	mov    0x14(%ebx),%eax
f0100806:	89 44 24 18          	mov    %eax,0x18(%esp)
f010080a:	8b 43 10             	mov    0x10(%ebx),%eax
f010080d:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100811:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100814:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100818:	8b 43 08             	mov    0x8(%ebx),%eax
f010081b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010081f:	8b 43 04             	mov    0x4(%ebx),%eax
f0100822:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100826:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010082a:	c7 04 24 e0 1e 10 f0 	movl   $0xf0101ee0,(%esp)
f0100831:	e8 e3 01 00 00       	call   f0100a19 <cprintf>
        ebp = p[0];
f0100836:	8b 1b                	mov    (%ebx),%ebx
 	int ret = debuginfo_eip((uintptr_t)p[1],&info);
f0100838:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010083c:	8b 46 04             	mov    0x4(%esi),%eax
f010083f:	89 04 24             	mov    %eax,(%esp)
f0100842:	e8 c9 02 00 00       	call   f0100b10 <debuginfo_eip>
	if (ret ==0)
f0100847:	85 c0                	test   %eax,%eax
f0100849:	75 34                	jne    f010087f <mon_backtrace+0xa4>
        cprintf("         %s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,p[1]-info.eip_fn_addr);
f010084b:	8b 46 04             	mov    0x4(%esi),%eax
f010084e:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100851:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100855:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100858:	89 44 24 10          	mov    %eax,0x10(%esp)
f010085c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010085f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100863:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100866:	89 44 24 08          	mov    %eax,0x8(%esp)
f010086a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010086d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100871:	c7 04 24 72 1d 10 f0 	movl   $0xf0101d72,(%esp)
f0100878:	e8 9c 01 00 00       	call   f0100a19 <cprintf>
f010087d:	eb 0c                	jmp    f010088b <mon_backtrace+0xb0>
        else 
        cprintf("search error");
f010087f:	c7 04 24 8b 1d 10 f0 	movl   $0xf0101d8b,(%esp)
f0100886:	e8 8e 01 00 00       	call   f0100a19 <cprintf>
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	uint32_t ebp ,*p;
	ebp = read_ebp();
	while (ebp != 0) {
f010088b:	85 db                	test   %ebx,%ebx
f010088d:	0f 85 67 ff ff ff    	jne    f01007fa <mon_backtrace+0x1f>
        cprintf("         %s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,p[1]-info.eip_fn_addr);
        else 
        cprintf("search error");
	}
	return 0;
}
f0100893:	b8 00 00 00 00       	mov    $0x0,%eax
f0100898:	83 c4 4c             	add    $0x4c,%esp
f010089b:	5b                   	pop    %ebx
f010089c:	5e                   	pop    %esi
f010089d:	5f                   	pop    %edi
f010089e:	5d                   	pop    %ebp
f010089f:	c3                   	ret    

f01008a0 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008a0:	55                   	push   %ebp
f01008a1:	89 e5                	mov    %esp,%ebp
f01008a3:	57                   	push   %edi
f01008a4:	56                   	push   %esi
f01008a5:	53                   	push   %ebx
f01008a6:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008a9:	c7 04 24 14 1f 10 f0 	movl   $0xf0101f14,(%esp)
f01008b0:	e8 64 01 00 00       	call   f0100a19 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008b5:	c7 04 24 38 1f 10 f0 	movl   $0xf0101f38,(%esp)
f01008bc:	e8 58 01 00 00       	call   f0100a19 <cprintf>


	while (1) {
		buf = readline("K> ");
f01008c1:	c7 04 24 98 1d 10 f0 	movl   $0xf0101d98,(%esp)
f01008c8:	e8 63 0a 00 00       	call   f0101330 <readline>
f01008cd:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008cf:	85 c0                	test   %eax,%eax
f01008d1:	74 ee                	je     f01008c1 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008d3:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008da:	be 00 00 00 00       	mov    $0x0,%esi
f01008df:	eb 0a                	jmp    f01008eb <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008e1:	c6 03 00             	movb   $0x0,(%ebx)
f01008e4:	89 f7                	mov    %esi,%edi
f01008e6:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008e9:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008eb:	0f b6 03             	movzbl (%ebx),%eax
f01008ee:	84 c0                	test   %al,%al
f01008f0:	74 63                	je     f0100955 <monitor+0xb5>
f01008f2:	0f be c0             	movsbl %al,%eax
f01008f5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008f9:	c7 04 24 9c 1d 10 f0 	movl   $0xf0101d9c,(%esp)
f0100900:	e8 45 0c 00 00       	call   f010154a <strchr>
f0100905:	85 c0                	test   %eax,%eax
f0100907:	75 d8                	jne    f01008e1 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100909:	80 3b 00             	cmpb   $0x0,(%ebx)
f010090c:	74 47                	je     f0100955 <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010090e:	83 fe 0f             	cmp    $0xf,%esi
f0100911:	75 16                	jne    f0100929 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100913:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010091a:	00 
f010091b:	c7 04 24 a1 1d 10 f0 	movl   $0xf0101da1,(%esp)
f0100922:	e8 f2 00 00 00       	call   f0100a19 <cprintf>
f0100927:	eb 98                	jmp    f01008c1 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100929:	8d 7e 01             	lea    0x1(%esi),%edi
f010092c:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100930:	eb 03                	jmp    f0100935 <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100932:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100935:	0f b6 03             	movzbl (%ebx),%eax
f0100938:	84 c0                	test   %al,%al
f010093a:	74 ad                	je     f01008e9 <monitor+0x49>
f010093c:	0f be c0             	movsbl %al,%eax
f010093f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100943:	c7 04 24 9c 1d 10 f0 	movl   $0xf0101d9c,(%esp)
f010094a:	e8 fb 0b 00 00       	call   f010154a <strchr>
f010094f:	85 c0                	test   %eax,%eax
f0100951:	74 df                	je     f0100932 <monitor+0x92>
f0100953:	eb 94                	jmp    f01008e9 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f0100955:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010095c:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010095d:	85 f6                	test   %esi,%esi
f010095f:	0f 84 5c ff ff ff    	je     f01008c1 <monitor+0x21>
f0100965:	bb 00 00 00 00       	mov    $0x0,%ebx
f010096a:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010096d:	8b 04 85 60 1f 10 f0 	mov    -0xfefe0a0(,%eax,4),%eax
f0100974:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100978:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010097b:	89 04 24             	mov    %eax,(%esp)
f010097e:	e8 69 0b 00 00       	call   f01014ec <strcmp>
f0100983:	85 c0                	test   %eax,%eax
f0100985:	75 24                	jne    f01009ab <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f0100987:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010098a:	8b 55 08             	mov    0x8(%ebp),%edx
f010098d:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100991:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100994:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100998:	89 34 24             	mov    %esi,(%esp)
f010099b:	ff 14 85 68 1f 10 f0 	call   *-0xfefe098(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009a2:	85 c0                	test   %eax,%eax
f01009a4:	78 25                	js     f01009cb <monitor+0x12b>
f01009a6:	e9 16 ff ff ff       	jmp    f01008c1 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009ab:	83 c3 01             	add    $0x1,%ebx
f01009ae:	83 fb 03             	cmp    $0x3,%ebx
f01009b1:	75 b7                	jne    f010096a <monitor+0xca>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009b3:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009b6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ba:	c7 04 24 be 1d 10 f0 	movl   $0xf0101dbe,(%esp)
f01009c1:	e8 53 00 00 00       	call   f0100a19 <cprintf>
f01009c6:	e9 f6 fe ff ff       	jmp    f01008c1 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009cb:	83 c4 5c             	add    $0x5c,%esp
f01009ce:	5b                   	pop    %ebx
f01009cf:	5e                   	pop    %esi
f01009d0:	5f                   	pop    %edi
f01009d1:	5d                   	pop    %ebp
f01009d2:	c3                   	ret    

f01009d3 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009d3:	55                   	push   %ebp
f01009d4:	89 e5                	mov    %esp,%ebp
f01009d6:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01009dc:	89 04 24             	mov    %eax,(%esp)
f01009df:	e8 9d fc ff ff       	call   f0100681 <cputchar>
	*cnt++;
}
f01009e4:	c9                   	leave  
f01009e5:	c3                   	ret    

f01009e6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009e6:	55                   	push   %ebp
f01009e7:	89 e5                	mov    %esp,%ebp
f01009e9:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009ec:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009f3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009f6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01009fd:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a01:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a04:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a08:	c7 04 24 d3 09 10 f0 	movl   $0xf01009d3,(%esp)
f0100a0f:	e8 ba 04 00 00       	call   f0100ece <vprintfmt>
	return cnt;
}
f0100a14:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a17:	c9                   	leave  
f0100a18:	c3                   	ret    

f0100a19 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a19:	55                   	push   %ebp
f0100a1a:	89 e5                	mov    %esp,%ebp
f0100a1c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a1f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a22:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a26:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a29:	89 04 24             	mov    %eax,(%esp)
f0100a2c:	e8 b5 ff ff ff       	call   f01009e6 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a31:	c9                   	leave  
f0100a32:	c3                   	ret    

f0100a33 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a33:	55                   	push   %ebp
f0100a34:	89 e5                	mov    %esp,%ebp
f0100a36:	57                   	push   %edi
f0100a37:	56                   	push   %esi
f0100a38:	53                   	push   %ebx
f0100a39:	83 ec 10             	sub    $0x10,%esp
f0100a3c:	89 c6                	mov    %eax,%esi
f0100a3e:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a41:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a44:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a47:	8b 1a                	mov    (%edx),%ebx
f0100a49:	8b 01                	mov    (%ecx),%eax
f0100a4b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a4e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a55:	eb 77                	jmp    f0100ace <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a57:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a5a:	01 d8                	add    %ebx,%eax
f0100a5c:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a61:	99                   	cltd   
f0100a62:	f7 f9                	idiv   %ecx
f0100a64:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a66:	eb 01                	jmp    f0100a69 <stab_binsearch+0x36>
			m--;
f0100a68:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a69:	39 d9                	cmp    %ebx,%ecx
f0100a6b:	7c 1d                	jl     f0100a8a <stab_binsearch+0x57>
f0100a6d:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a70:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a75:	39 fa                	cmp    %edi,%edx
f0100a77:	75 ef                	jne    f0100a68 <stab_binsearch+0x35>
f0100a79:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a7c:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a7f:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a83:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a86:	73 18                	jae    f0100aa0 <stab_binsearch+0x6d>
f0100a88:	eb 05                	jmp    f0100a8f <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a8a:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a8d:	eb 3f                	jmp    f0100ace <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a8f:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a92:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a94:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a97:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a9e:	eb 2e                	jmp    f0100ace <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100aa0:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100aa3:	73 15                	jae    f0100aba <stab_binsearch+0x87>
			*region_right = m - 1;
f0100aa5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100aa8:	48                   	dec    %eax
f0100aa9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100aac:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100aaf:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ab1:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100ab8:	eb 14                	jmp    f0100ace <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100aba:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100abd:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100ac0:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100ac2:	ff 45 0c             	incl   0xc(%ebp)
f0100ac5:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ac7:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100ace:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100ad1:	7e 84                	jle    f0100a57 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ad3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100ad7:	75 0d                	jne    f0100ae6 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100ad9:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100adc:	8b 00                	mov    (%eax),%eax
f0100ade:	48                   	dec    %eax
f0100adf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ae2:	89 07                	mov    %eax,(%edi)
f0100ae4:	eb 22                	jmp    f0100b08 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ae9:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100aeb:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100aee:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100af0:	eb 01                	jmp    f0100af3 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100af2:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100af3:	39 c1                	cmp    %eax,%ecx
f0100af5:	7d 0c                	jge    f0100b03 <stab_binsearch+0xd0>
f0100af7:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100afa:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100aff:	39 fa                	cmp    %edi,%edx
f0100b01:	75 ef                	jne    f0100af2 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b03:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100b06:	89 07                	mov    %eax,(%edi)
	}
}
f0100b08:	83 c4 10             	add    $0x10,%esp
f0100b0b:	5b                   	pop    %ebx
f0100b0c:	5e                   	pop    %esi
f0100b0d:	5f                   	pop    %edi
f0100b0e:	5d                   	pop    %ebp
f0100b0f:	c3                   	ret    

f0100b10 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b10:	55                   	push   %ebp
f0100b11:	89 e5                	mov    %esp,%ebp
f0100b13:	57                   	push   %edi
f0100b14:	56                   	push   %esi
f0100b15:	53                   	push   %ebx
f0100b16:	83 ec 3c             	sub    $0x3c,%esp
f0100b19:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b1c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b1f:	c7 03 84 1f 10 f0    	movl   $0xf0101f84,(%ebx)
	info->eip_line = 0;
f0100b25:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b2c:	c7 43 08 84 1f 10 f0 	movl   $0xf0101f84,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b33:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b3a:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b3d:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b44:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b4a:	76 12                	jbe    f0100b5e <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b4c:	b8 bb 74 10 f0       	mov    $0xf01074bb,%eax
f0100b51:	3d 95 5b 10 f0       	cmp    $0xf0105b95,%eax
f0100b56:	0f 86 cd 01 00 00    	jbe    f0100d29 <debuginfo_eip+0x219>
f0100b5c:	eb 1c                	jmp    f0100b7a <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b5e:	c7 44 24 08 8e 1f 10 	movl   $0xf0101f8e,0x8(%esp)
f0100b65:	f0 
f0100b66:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b6d:	00 
f0100b6e:	c7 04 24 9b 1f 10 f0 	movl   $0xf0101f9b,(%esp)
f0100b75:	e8 a2 f5 ff ff       	call   f010011c <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b7a:	80 3d ba 74 10 f0 00 	cmpb   $0x0,0xf01074ba
f0100b81:	0f 85 a9 01 00 00    	jne    f0100d30 <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b87:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b8e:	b8 94 5b 10 f0       	mov    $0xf0105b94,%eax
f0100b93:	2d bc 21 10 f0       	sub    $0xf01021bc,%eax
f0100b98:	c1 f8 02             	sar    $0x2,%eax
f0100b9b:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100ba1:	83 e8 01             	sub    $0x1,%eax
f0100ba4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ba7:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bab:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100bb2:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100bb5:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100bb8:	b8 bc 21 10 f0       	mov    $0xf01021bc,%eax
f0100bbd:	e8 71 fe ff ff       	call   f0100a33 <stab_binsearch>
	if (lfile == 0)
f0100bc2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bc5:	85 c0                	test   %eax,%eax
f0100bc7:	0f 84 6a 01 00 00    	je     f0100d37 <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bcd:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bd0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bd3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bd6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bda:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100be1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100be4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100be7:	b8 bc 21 10 f0       	mov    $0xf01021bc,%eax
f0100bec:	e8 42 fe ff ff       	call   f0100a33 <stab_binsearch>

	if (lfun <= rfun) {
f0100bf1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bf4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100bf7:	39 d0                	cmp    %edx,%eax
f0100bf9:	7f 3d                	jg     f0100c38 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bfb:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100bfe:	8d b9 bc 21 10 f0    	lea    -0xfefde44(%ecx),%edi
f0100c04:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100c07:	8b 89 bc 21 10 f0    	mov    -0xfefde44(%ecx),%ecx
f0100c0d:	bf bb 74 10 f0       	mov    $0xf01074bb,%edi
f0100c12:	81 ef 95 5b 10 f0    	sub    $0xf0105b95,%edi
f0100c18:	39 f9                	cmp    %edi,%ecx
f0100c1a:	73 09                	jae    f0100c25 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c1c:	81 c1 95 5b 10 f0    	add    $0xf0105b95,%ecx
f0100c22:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c25:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c28:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c2b:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c2e:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c30:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c33:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c36:	eb 0f                	jmp    f0100c47 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c38:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c3b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c3e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c41:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c44:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c47:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c4e:	00 
f0100c4f:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c52:	89 04 24             	mov    %eax,(%esp)
f0100c55:	e8 11 09 00 00       	call   f010156b <strfind>
f0100c5a:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c5d:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
         stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
f0100c60:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c64:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c6b:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c6e:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c71:	b8 bc 21 10 f0       	mov    $0xf01021bc,%eax
f0100c76:	e8 b8 fd ff ff       	call   f0100a33 <stab_binsearch>
         if (lline > rline) {
f0100c7b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c7e:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100c81:	0f 8f b7 00 00 00    	jg     f0100d3e <debuginfo_eip+0x22e>
         return -1;
         }
         info->eip_line = stabs[lline].n_desc;
f0100c87:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c8a:	0f b7 80 c2 21 10 f0 	movzwl -0xfefde3e(%eax),%eax
f0100c91:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c94:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c97:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100c9a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c9d:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100ca0:	81 c2 bc 21 10 f0    	add    $0xf01021bc,%edx
f0100ca6:	eb 06                	jmp    f0100cae <debuginfo_eip+0x19e>
f0100ca8:	83 e8 01             	sub    $0x1,%eax
f0100cab:	83 ea 0c             	sub    $0xc,%edx
f0100cae:	89 c6                	mov    %eax,%esi
f0100cb0:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100cb3:	7f 33                	jg     f0100ce8 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0100cb5:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100cb9:	80 f9 84             	cmp    $0x84,%cl
f0100cbc:	74 0b                	je     f0100cc9 <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cbe:	80 f9 64             	cmp    $0x64,%cl
f0100cc1:	75 e5                	jne    f0100ca8 <debuginfo_eip+0x198>
f0100cc3:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100cc7:	74 df                	je     f0100ca8 <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cc9:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100ccc:	8b 86 bc 21 10 f0    	mov    -0xfefde44(%esi),%eax
f0100cd2:	ba bb 74 10 f0       	mov    $0xf01074bb,%edx
f0100cd7:	81 ea 95 5b 10 f0    	sub    $0xf0105b95,%edx
f0100cdd:	39 d0                	cmp    %edx,%eax
f0100cdf:	73 07                	jae    f0100ce8 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100ce1:	05 95 5b 10 f0       	add    $0xf0105b95,%eax
f0100ce6:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ce8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ceb:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cee:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cf3:	39 ca                	cmp    %ecx,%edx
f0100cf5:	7d 53                	jge    f0100d4a <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0100cf7:	8d 42 01             	lea    0x1(%edx),%eax
f0100cfa:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100cfd:	89 c2                	mov    %eax,%edx
f0100cff:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100d02:	05 bc 21 10 f0       	add    $0xf01021bc,%eax
f0100d07:	89 ce                	mov    %ecx,%esi
f0100d09:	eb 04                	jmp    f0100d0f <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d0b:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d0f:	39 d6                	cmp    %edx,%esi
f0100d11:	7e 32                	jle    f0100d45 <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d13:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100d17:	83 c2 01             	add    $0x1,%edx
f0100d1a:	83 c0 0c             	add    $0xc,%eax
f0100d1d:	80 f9 a0             	cmp    $0xa0,%cl
f0100d20:	74 e9                	je     f0100d0b <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d22:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d27:	eb 21                	jmp    f0100d4a <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d29:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d2e:	eb 1a                	jmp    f0100d4a <debuginfo_eip+0x23a>
f0100d30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d35:	eb 13                	jmp    f0100d4a <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d3c:	eb 0c                	jmp    f0100d4a <debuginfo_eip+0x23a>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
         stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
         if (lline > rline) {
         return -1;
f0100d3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d43:	eb 05                	jmp    f0100d4a <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d45:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d4a:	83 c4 3c             	add    $0x3c,%esp
f0100d4d:	5b                   	pop    %ebx
f0100d4e:	5e                   	pop    %esi
f0100d4f:	5f                   	pop    %edi
f0100d50:	5d                   	pop    %ebp
f0100d51:	c3                   	ret    
f0100d52:	66 90                	xchg   %ax,%ax
f0100d54:	66 90                	xchg   %ax,%ax
f0100d56:	66 90                	xchg   %ax,%ax
f0100d58:	66 90                	xchg   %ax,%ax
f0100d5a:	66 90                	xchg   %ax,%ax
f0100d5c:	66 90                	xchg   %ax,%ax
f0100d5e:	66 90                	xchg   %ax,%ax

f0100d60 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d60:	55                   	push   %ebp
f0100d61:	89 e5                	mov    %esp,%ebp
f0100d63:	57                   	push   %edi
f0100d64:	56                   	push   %esi
f0100d65:	53                   	push   %ebx
f0100d66:	83 ec 3c             	sub    $0x3c,%esp
f0100d69:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d6c:	89 d7                	mov    %edx,%edi
f0100d6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d71:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d74:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d77:	89 c3                	mov    %eax,%ebx
f0100d79:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d7c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d7f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d82:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d87:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d8a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d8d:	39 d9                	cmp    %ebx,%ecx
f0100d8f:	72 05                	jb     f0100d96 <printnum+0x36>
f0100d91:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d94:	77 69                	ja     f0100dff <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d96:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d99:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d9d:	83 ee 01             	sub    $0x1,%esi
f0100da0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100da4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100da8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100dac:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100db0:	89 c3                	mov    %eax,%ebx
f0100db2:	89 d6                	mov    %edx,%esi
f0100db4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100db7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100dba:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100dbe:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100dc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dc5:	89 04 24             	mov    %eax,(%esp)
f0100dc8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dcb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dcf:	e8 bc 09 00 00       	call   f0101790 <__udivdi3>
f0100dd4:	89 d9                	mov    %ebx,%ecx
f0100dd6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100dda:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100dde:	89 04 24             	mov    %eax,(%esp)
f0100de1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100de5:	89 fa                	mov    %edi,%edx
f0100de7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dea:	e8 71 ff ff ff       	call   f0100d60 <printnum>
f0100def:	eb 1b                	jmp    f0100e0c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100df1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100df5:	8b 45 18             	mov    0x18(%ebp),%eax
f0100df8:	89 04 24             	mov    %eax,(%esp)
f0100dfb:	ff d3                	call   *%ebx
f0100dfd:	eb 03                	jmp    f0100e02 <printnum+0xa2>
f0100dff:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e02:	83 ee 01             	sub    $0x1,%esi
f0100e05:	85 f6                	test   %esi,%esi
f0100e07:	7f e8                	jg     f0100df1 <printnum+0x91>
f0100e09:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e0c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e10:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e14:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e17:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e1a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e1e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100e22:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e25:	89 04 24             	mov    %eax,(%esp)
f0100e28:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e2b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e2f:	e8 8c 0a 00 00       	call   f01018c0 <__umoddi3>
f0100e34:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e38:	0f be 80 a9 1f 10 f0 	movsbl -0xfefe057(%eax),%eax
f0100e3f:	89 04 24             	mov    %eax,(%esp)
f0100e42:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e45:	ff d0                	call   *%eax
}
f0100e47:	83 c4 3c             	add    $0x3c,%esp
f0100e4a:	5b                   	pop    %ebx
f0100e4b:	5e                   	pop    %esi
f0100e4c:	5f                   	pop    %edi
f0100e4d:	5d                   	pop    %ebp
f0100e4e:	c3                   	ret    

f0100e4f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e4f:	55                   	push   %ebp
f0100e50:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e52:	83 fa 01             	cmp    $0x1,%edx
f0100e55:	7e 0e                	jle    f0100e65 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e57:	8b 10                	mov    (%eax),%edx
f0100e59:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e5c:	89 08                	mov    %ecx,(%eax)
f0100e5e:	8b 02                	mov    (%edx),%eax
f0100e60:	8b 52 04             	mov    0x4(%edx),%edx
f0100e63:	eb 22                	jmp    f0100e87 <getuint+0x38>
	else if (lflag)
f0100e65:	85 d2                	test   %edx,%edx
f0100e67:	74 10                	je     f0100e79 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e69:	8b 10                	mov    (%eax),%edx
f0100e6b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e6e:	89 08                	mov    %ecx,(%eax)
f0100e70:	8b 02                	mov    (%edx),%eax
f0100e72:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e77:	eb 0e                	jmp    f0100e87 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e79:	8b 10                	mov    (%eax),%edx
f0100e7b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e7e:	89 08                	mov    %ecx,(%eax)
f0100e80:	8b 02                	mov    (%edx),%eax
f0100e82:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e87:	5d                   	pop    %ebp
f0100e88:	c3                   	ret    

f0100e89 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e89:	55                   	push   %ebp
f0100e8a:	89 e5                	mov    %esp,%ebp
f0100e8c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e8f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e93:	8b 10                	mov    (%eax),%edx
f0100e95:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e98:	73 0a                	jae    f0100ea4 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e9a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e9d:	89 08                	mov    %ecx,(%eax)
f0100e9f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ea2:	88 02                	mov    %al,(%edx)
}
f0100ea4:	5d                   	pop    %ebp
f0100ea5:	c3                   	ret    

f0100ea6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100ea6:	55                   	push   %ebp
f0100ea7:	89 e5                	mov    %esp,%ebp
f0100ea9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100eac:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100eaf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100eb3:	8b 45 10             	mov    0x10(%ebp),%eax
f0100eb6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100eba:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ebd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ec1:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ec4:	89 04 24             	mov    %eax,(%esp)
f0100ec7:	e8 02 00 00 00       	call   f0100ece <vprintfmt>
	va_end(ap);
}
f0100ecc:	c9                   	leave  
f0100ecd:	c3                   	ret    

f0100ece <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ece:	55                   	push   %ebp
f0100ecf:	89 e5                	mov    %esp,%ebp
f0100ed1:	57                   	push   %edi
f0100ed2:	56                   	push   %esi
f0100ed3:	53                   	push   %ebx
f0100ed4:	83 ec 3c             	sub    $0x3c,%esp
f0100ed7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100eda:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100edd:	eb 14                	jmp    f0100ef3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100edf:	85 c0                	test   %eax,%eax
f0100ee1:	0f 84 b3 03 00 00    	je     f010129a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0100ee7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100eeb:	89 04 24             	mov    %eax,(%esp)
f0100eee:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ef1:	89 f3                	mov    %esi,%ebx
f0100ef3:	8d 73 01             	lea    0x1(%ebx),%esi
f0100ef6:	0f b6 03             	movzbl (%ebx),%eax
f0100ef9:	83 f8 25             	cmp    $0x25,%eax
f0100efc:	75 e1                	jne    f0100edf <vprintfmt+0x11>
f0100efe:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100f02:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100f09:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100f10:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100f17:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f1c:	eb 1d                	jmp    f0100f3b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f1e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f20:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100f24:	eb 15                	jmp    f0100f3b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f26:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f28:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100f2c:	eb 0d                	jmp    f0100f3b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f31:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f34:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3b:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100f3e:	0f b6 0e             	movzbl (%esi),%ecx
f0100f41:	0f b6 c1             	movzbl %cl,%eax
f0100f44:	83 e9 23             	sub    $0x23,%ecx
f0100f47:	80 f9 55             	cmp    $0x55,%cl
f0100f4a:	0f 87 2a 03 00 00    	ja     f010127a <vprintfmt+0x3ac>
f0100f50:	0f b6 c9             	movzbl %cl,%ecx
f0100f53:	ff 24 8d 38 20 10 f0 	jmp    *-0xfefdfc8(,%ecx,4)
f0100f5a:	89 de                	mov    %ebx,%esi
f0100f5c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f61:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f64:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f68:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f6b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f6e:	83 fb 09             	cmp    $0x9,%ebx
f0100f71:	77 36                	ja     f0100fa9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f73:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f76:	eb e9                	jmp    f0100f61 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f78:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f7b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f7e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f81:	8b 00                	mov    (%eax),%eax
f0100f83:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f86:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f88:	eb 22                	jmp    f0100fac <vprintfmt+0xde>
f0100f8a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f8d:	85 c9                	test   %ecx,%ecx
f0100f8f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f94:	0f 49 c1             	cmovns %ecx,%eax
f0100f97:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f9a:	89 de                	mov    %ebx,%esi
f0100f9c:	eb 9d                	jmp    f0100f3b <vprintfmt+0x6d>
f0100f9e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100fa0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100fa7:	eb 92                	jmp    f0100f3b <vprintfmt+0x6d>
f0100fa9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0100fac:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100fb0:	79 89                	jns    f0100f3b <vprintfmt+0x6d>
f0100fb2:	e9 77 ff ff ff       	jmp    f0100f2e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fb7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fba:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100fbc:	e9 7a ff ff ff       	jmp    f0100f3b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fc1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fc4:	8d 50 04             	lea    0x4(%eax),%edx
f0100fc7:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fca:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fce:	8b 00                	mov    (%eax),%eax
f0100fd0:	89 04 24             	mov    %eax,(%esp)
f0100fd3:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100fd6:	e9 18 ff ff ff       	jmp    f0100ef3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fdb:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fde:	8d 50 04             	lea    0x4(%eax),%edx
f0100fe1:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fe4:	8b 00                	mov    (%eax),%eax
f0100fe6:	99                   	cltd   
f0100fe7:	31 d0                	xor    %edx,%eax
f0100fe9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100feb:	83 f8 06             	cmp    $0x6,%eax
f0100fee:	7f 0b                	jg     f0100ffb <vprintfmt+0x12d>
f0100ff0:	8b 14 85 90 21 10 f0 	mov    -0xfefde70(,%eax,4),%edx
f0100ff7:	85 d2                	test   %edx,%edx
f0100ff9:	75 20                	jne    f010101b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0100ffb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fff:	c7 44 24 08 c1 1f 10 	movl   $0xf0101fc1,0x8(%esp)
f0101006:	f0 
f0101007:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010100b:	8b 45 08             	mov    0x8(%ebp),%eax
f010100e:	89 04 24             	mov    %eax,(%esp)
f0101011:	e8 90 fe ff ff       	call   f0100ea6 <printfmt>
f0101016:	e9 d8 fe ff ff       	jmp    f0100ef3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010101b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010101f:	c7 44 24 08 ca 1f 10 	movl   $0xf0101fca,0x8(%esp)
f0101026:	f0 
f0101027:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010102b:	8b 45 08             	mov    0x8(%ebp),%eax
f010102e:	89 04 24             	mov    %eax,(%esp)
f0101031:	e8 70 fe ff ff       	call   f0100ea6 <printfmt>
f0101036:	e9 b8 fe ff ff       	jmp    f0100ef3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010103b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010103e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101041:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101044:	8b 45 14             	mov    0x14(%ebp),%eax
f0101047:	8d 50 04             	lea    0x4(%eax),%edx
f010104a:	89 55 14             	mov    %edx,0x14(%ebp)
f010104d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010104f:	85 f6                	test   %esi,%esi
f0101051:	b8 ba 1f 10 f0       	mov    $0xf0101fba,%eax
f0101056:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0101059:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010105d:	0f 84 97 00 00 00    	je     f01010fa <vprintfmt+0x22c>
f0101063:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101067:	0f 8e 9b 00 00 00    	jle    f0101108 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010106d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101071:	89 34 24             	mov    %esi,(%esp)
f0101074:	e8 9f 03 00 00       	call   f0101418 <strnlen>
f0101079:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010107c:	29 c2                	sub    %eax,%edx
f010107e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0101081:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0101085:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101088:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010108b:	8b 75 08             	mov    0x8(%ebp),%esi
f010108e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101091:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101093:	eb 0f                	jmp    f01010a4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0101095:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101099:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010109c:	89 04 24             	mov    %eax,(%esp)
f010109f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010a1:	83 eb 01             	sub    $0x1,%ebx
f01010a4:	85 db                	test   %ebx,%ebx
f01010a6:	7f ed                	jg     f0101095 <vprintfmt+0x1c7>
f01010a8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01010ab:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01010ae:	85 d2                	test   %edx,%edx
f01010b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01010b5:	0f 49 c2             	cmovns %edx,%eax
f01010b8:	29 c2                	sub    %eax,%edx
f01010ba:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010bd:	89 d7                	mov    %edx,%edi
f01010bf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010c2:	eb 50                	jmp    f0101114 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010c4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01010c8:	74 1e                	je     f01010e8 <vprintfmt+0x21a>
f01010ca:	0f be d2             	movsbl %dl,%edx
f01010cd:	83 ea 20             	sub    $0x20,%edx
f01010d0:	83 fa 5e             	cmp    $0x5e,%edx
f01010d3:	76 13                	jbe    f01010e8 <vprintfmt+0x21a>
					putch('?', putdat);
f01010d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010dc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010e3:	ff 55 08             	call   *0x8(%ebp)
f01010e6:	eb 0d                	jmp    f01010f5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f01010e8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01010eb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010ef:	89 04 24             	mov    %eax,(%esp)
f01010f2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010f5:	83 ef 01             	sub    $0x1,%edi
f01010f8:	eb 1a                	jmp    f0101114 <vprintfmt+0x246>
f01010fa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010fd:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101100:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101103:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101106:	eb 0c                	jmp    f0101114 <vprintfmt+0x246>
f0101108:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010110b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010110e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101111:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101114:	83 c6 01             	add    $0x1,%esi
f0101117:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010111b:	0f be c2             	movsbl %dl,%eax
f010111e:	85 c0                	test   %eax,%eax
f0101120:	74 27                	je     f0101149 <vprintfmt+0x27b>
f0101122:	85 db                	test   %ebx,%ebx
f0101124:	78 9e                	js     f01010c4 <vprintfmt+0x1f6>
f0101126:	83 eb 01             	sub    $0x1,%ebx
f0101129:	79 99                	jns    f01010c4 <vprintfmt+0x1f6>
f010112b:	89 f8                	mov    %edi,%eax
f010112d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101130:	8b 75 08             	mov    0x8(%ebp),%esi
f0101133:	89 c3                	mov    %eax,%ebx
f0101135:	eb 1a                	jmp    f0101151 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101137:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010113b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101142:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101144:	83 eb 01             	sub    $0x1,%ebx
f0101147:	eb 08                	jmp    f0101151 <vprintfmt+0x283>
f0101149:	89 fb                	mov    %edi,%ebx
f010114b:	8b 75 08             	mov    0x8(%ebp),%esi
f010114e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101151:	85 db                	test   %ebx,%ebx
f0101153:	7f e2                	jg     f0101137 <vprintfmt+0x269>
f0101155:	89 75 08             	mov    %esi,0x8(%ebp)
f0101158:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010115b:	e9 93 fd ff ff       	jmp    f0100ef3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101160:	83 fa 01             	cmp    $0x1,%edx
f0101163:	7e 16                	jle    f010117b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0101165:	8b 45 14             	mov    0x14(%ebp),%eax
f0101168:	8d 50 08             	lea    0x8(%eax),%edx
f010116b:	89 55 14             	mov    %edx,0x14(%ebp)
f010116e:	8b 50 04             	mov    0x4(%eax),%edx
f0101171:	8b 00                	mov    (%eax),%eax
f0101173:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101176:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101179:	eb 32                	jmp    f01011ad <vprintfmt+0x2df>
	else if (lflag)
f010117b:	85 d2                	test   %edx,%edx
f010117d:	74 18                	je     f0101197 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010117f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101182:	8d 50 04             	lea    0x4(%eax),%edx
f0101185:	89 55 14             	mov    %edx,0x14(%ebp)
f0101188:	8b 30                	mov    (%eax),%esi
f010118a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010118d:	89 f0                	mov    %esi,%eax
f010118f:	c1 f8 1f             	sar    $0x1f,%eax
f0101192:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101195:	eb 16                	jmp    f01011ad <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0101197:	8b 45 14             	mov    0x14(%ebp),%eax
f010119a:	8d 50 04             	lea    0x4(%eax),%edx
f010119d:	89 55 14             	mov    %edx,0x14(%ebp)
f01011a0:	8b 30                	mov    (%eax),%esi
f01011a2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01011a5:	89 f0                	mov    %esi,%eax
f01011a7:	c1 f8 1f             	sar    $0x1f,%eax
f01011aa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01011ad:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011b0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01011b3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01011b8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01011bc:	0f 89 80 00 00 00    	jns    f0101242 <vprintfmt+0x374>
				putch('-', putdat);
f01011c2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011c6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01011cd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01011d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011d3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01011d6:	f7 d8                	neg    %eax
f01011d8:	83 d2 00             	adc    $0x0,%edx
f01011db:	f7 da                	neg    %edx
			}
			base = 10;
f01011dd:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01011e2:	eb 5e                	jmp    f0101242 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01011e4:	8d 45 14             	lea    0x14(%ebp),%eax
f01011e7:	e8 63 fc ff ff       	call   f0100e4f <getuint>
			base = 10;
f01011ec:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01011f1:	eb 4f                	jmp    f0101242 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f01011f3:	8d 45 14             	lea    0x14(%ebp),%eax
f01011f6:	e8 54 fc ff ff       	call   f0100e4f <getuint>
			base = 8;
f01011fb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101200:	eb 40                	jmp    f0101242 <vprintfmt+0x374>
		// pointer
		case 'p':
			putch('0', putdat);
f0101202:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101206:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010120d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101210:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101214:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010121b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010121e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101221:	8d 50 04             	lea    0x4(%eax),%edx
f0101224:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101227:	8b 00                	mov    (%eax),%eax
f0101229:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010122e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101233:	eb 0d                	jmp    f0101242 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101235:	8d 45 14             	lea    0x14(%ebp),%eax
f0101238:	e8 12 fc ff ff       	call   f0100e4f <getuint>
			base = 16;
f010123d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101242:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0101246:	89 74 24 10          	mov    %esi,0x10(%esp)
f010124a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010124d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101251:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101255:	89 04 24             	mov    %eax,(%esp)
f0101258:	89 54 24 04          	mov    %edx,0x4(%esp)
f010125c:	89 fa                	mov    %edi,%edx
f010125e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101261:	e8 fa fa ff ff       	call   f0100d60 <printnum>
			break;
f0101266:	e9 88 fc ff ff       	jmp    f0100ef3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010126b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010126f:	89 04 24             	mov    %eax,(%esp)
f0101272:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101275:	e9 79 fc ff ff       	jmp    f0100ef3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010127a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010127e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101285:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101288:	89 f3                	mov    %esi,%ebx
f010128a:	eb 03                	jmp    f010128f <vprintfmt+0x3c1>
f010128c:	83 eb 01             	sub    $0x1,%ebx
f010128f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101293:	75 f7                	jne    f010128c <vprintfmt+0x3be>
f0101295:	e9 59 fc ff ff       	jmp    f0100ef3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010129a:	83 c4 3c             	add    $0x3c,%esp
f010129d:	5b                   	pop    %ebx
f010129e:	5e                   	pop    %esi
f010129f:	5f                   	pop    %edi
f01012a0:	5d                   	pop    %ebp
f01012a1:	c3                   	ret    

f01012a2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012a2:	55                   	push   %ebp
f01012a3:	89 e5                	mov    %esp,%ebp
f01012a5:	83 ec 28             	sub    $0x28,%esp
f01012a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01012ab:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012ae:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012b1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01012b5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01012b8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01012bf:	85 c0                	test   %eax,%eax
f01012c1:	74 30                	je     f01012f3 <vsnprintf+0x51>
f01012c3:	85 d2                	test   %edx,%edx
f01012c5:	7e 2c                	jle    f01012f3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01012c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01012ca:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012ce:	8b 45 10             	mov    0x10(%ebp),%eax
f01012d1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012d5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01012d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012dc:	c7 04 24 89 0e 10 f0 	movl   $0xf0100e89,(%esp)
f01012e3:	e8 e6 fb ff ff       	call   f0100ece <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012e8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012eb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012f1:	eb 05                	jmp    f01012f8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012f3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012f8:	c9                   	leave  
f01012f9:	c3                   	ret    

f01012fa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012fa:	55                   	push   %ebp
f01012fb:	89 e5                	mov    %esp,%ebp
f01012fd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101300:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101303:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101307:	8b 45 10             	mov    0x10(%ebp),%eax
f010130a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010130e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101311:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101315:	8b 45 08             	mov    0x8(%ebp),%eax
f0101318:	89 04 24             	mov    %eax,(%esp)
f010131b:	e8 82 ff ff ff       	call   f01012a2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101320:	c9                   	leave  
f0101321:	c3                   	ret    
f0101322:	66 90                	xchg   %ax,%ax
f0101324:	66 90                	xchg   %ax,%ax
f0101326:	66 90                	xchg   %ax,%ax
f0101328:	66 90                	xchg   %ax,%ax
f010132a:	66 90                	xchg   %ax,%ax
f010132c:	66 90                	xchg   %ax,%ax
f010132e:	66 90                	xchg   %ax,%ax

f0101330 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101330:	55                   	push   %ebp
f0101331:	89 e5                	mov    %esp,%ebp
f0101333:	57                   	push   %edi
f0101334:	56                   	push   %esi
f0101335:	53                   	push   %ebx
f0101336:	83 ec 1c             	sub    $0x1c,%esp
f0101339:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010133c:	85 c0                	test   %eax,%eax
f010133e:	74 10                	je     f0101350 <readline+0x20>
		cprintf("%s", prompt);
f0101340:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101344:	c7 04 24 ca 1f 10 f0 	movl   $0xf0101fca,(%esp)
f010134b:	e8 c9 f6 ff ff       	call   f0100a19 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101350:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101357:	e8 46 f3 ff ff       	call   f01006a2 <iscons>
f010135c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010135e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101363:	e8 29 f3 ff ff       	call   f0100691 <getchar>
f0101368:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010136a:	85 c0                	test   %eax,%eax
f010136c:	79 17                	jns    f0101385 <readline+0x55>
			cprintf("read error: %e\n", c);
f010136e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101372:	c7 04 24 ac 21 10 f0 	movl   $0xf01021ac,(%esp)
f0101379:	e8 9b f6 ff ff       	call   f0100a19 <cprintf>
			return NULL;
f010137e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101383:	eb 6d                	jmp    f01013f2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101385:	83 f8 7f             	cmp    $0x7f,%eax
f0101388:	74 05                	je     f010138f <readline+0x5f>
f010138a:	83 f8 08             	cmp    $0x8,%eax
f010138d:	75 19                	jne    f01013a8 <readline+0x78>
f010138f:	85 f6                	test   %esi,%esi
f0101391:	7e 15                	jle    f01013a8 <readline+0x78>
			if (echoing)
f0101393:	85 ff                	test   %edi,%edi
f0101395:	74 0c                	je     f01013a3 <readline+0x73>
				cputchar('\b');
f0101397:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010139e:	e8 de f2 ff ff       	call   f0100681 <cputchar>
			i--;
f01013a3:	83 ee 01             	sub    $0x1,%esi
f01013a6:	eb bb                	jmp    f0101363 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01013a8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01013ae:	7f 1c                	jg     f01013cc <readline+0x9c>
f01013b0:	83 fb 1f             	cmp    $0x1f,%ebx
f01013b3:	7e 17                	jle    f01013cc <readline+0x9c>
			if (echoing)
f01013b5:	85 ff                	test   %edi,%edi
f01013b7:	74 08                	je     f01013c1 <readline+0x91>
				cputchar(c);
f01013b9:	89 1c 24             	mov    %ebx,(%esp)
f01013bc:	e8 c0 f2 ff ff       	call   f0100681 <cputchar>
			buf[i++] = c;
f01013c1:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01013c7:	8d 76 01             	lea    0x1(%esi),%esi
f01013ca:	eb 97                	jmp    f0101363 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01013cc:	83 fb 0d             	cmp    $0xd,%ebx
f01013cf:	74 05                	je     f01013d6 <readline+0xa6>
f01013d1:	83 fb 0a             	cmp    $0xa,%ebx
f01013d4:	75 8d                	jne    f0101363 <readline+0x33>
			if (echoing)
f01013d6:	85 ff                	test   %edi,%edi
f01013d8:	74 0c                	je     f01013e6 <readline+0xb6>
				cputchar('\n');
f01013da:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01013e1:	e8 9b f2 ff ff       	call   f0100681 <cputchar>
			buf[i] = 0;
f01013e6:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01013ed:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01013f2:	83 c4 1c             	add    $0x1c,%esp
f01013f5:	5b                   	pop    %ebx
f01013f6:	5e                   	pop    %esi
f01013f7:	5f                   	pop    %edi
f01013f8:	5d                   	pop    %ebp
f01013f9:	c3                   	ret    
f01013fa:	66 90                	xchg   %ax,%ax
f01013fc:	66 90                	xchg   %ax,%ax
f01013fe:	66 90                	xchg   %ax,%ax

f0101400 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101400:	55                   	push   %ebp
f0101401:	89 e5                	mov    %esp,%ebp
f0101403:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101406:	b8 00 00 00 00       	mov    $0x0,%eax
f010140b:	eb 03                	jmp    f0101410 <strlen+0x10>
		n++;
f010140d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101410:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101414:	75 f7                	jne    f010140d <strlen+0xd>
		n++;
	return n;
}
f0101416:	5d                   	pop    %ebp
f0101417:	c3                   	ret    

f0101418 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101418:	55                   	push   %ebp
f0101419:	89 e5                	mov    %esp,%ebp
f010141b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010141e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101421:	b8 00 00 00 00       	mov    $0x0,%eax
f0101426:	eb 03                	jmp    f010142b <strnlen+0x13>
		n++;
f0101428:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010142b:	39 d0                	cmp    %edx,%eax
f010142d:	74 06                	je     f0101435 <strnlen+0x1d>
f010142f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101433:	75 f3                	jne    f0101428 <strnlen+0x10>
		n++;
	return n;
}
f0101435:	5d                   	pop    %ebp
f0101436:	c3                   	ret    

f0101437 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101437:	55                   	push   %ebp
f0101438:	89 e5                	mov    %esp,%ebp
f010143a:	53                   	push   %ebx
f010143b:	8b 45 08             	mov    0x8(%ebp),%eax
f010143e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101441:	89 c2                	mov    %eax,%edx
f0101443:	83 c2 01             	add    $0x1,%edx
f0101446:	83 c1 01             	add    $0x1,%ecx
f0101449:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010144d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101450:	84 db                	test   %bl,%bl
f0101452:	75 ef                	jne    f0101443 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101454:	5b                   	pop    %ebx
f0101455:	5d                   	pop    %ebp
f0101456:	c3                   	ret    

f0101457 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101457:	55                   	push   %ebp
f0101458:	89 e5                	mov    %esp,%ebp
f010145a:	53                   	push   %ebx
f010145b:	83 ec 08             	sub    $0x8,%esp
f010145e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101461:	89 1c 24             	mov    %ebx,(%esp)
f0101464:	e8 97 ff ff ff       	call   f0101400 <strlen>
	strcpy(dst + len, src);
f0101469:	8b 55 0c             	mov    0xc(%ebp),%edx
f010146c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101470:	01 d8                	add    %ebx,%eax
f0101472:	89 04 24             	mov    %eax,(%esp)
f0101475:	e8 bd ff ff ff       	call   f0101437 <strcpy>
	return dst;
}
f010147a:	89 d8                	mov    %ebx,%eax
f010147c:	83 c4 08             	add    $0x8,%esp
f010147f:	5b                   	pop    %ebx
f0101480:	5d                   	pop    %ebp
f0101481:	c3                   	ret    

f0101482 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101482:	55                   	push   %ebp
f0101483:	89 e5                	mov    %esp,%ebp
f0101485:	56                   	push   %esi
f0101486:	53                   	push   %ebx
f0101487:	8b 75 08             	mov    0x8(%ebp),%esi
f010148a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010148d:	89 f3                	mov    %esi,%ebx
f010148f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101492:	89 f2                	mov    %esi,%edx
f0101494:	eb 0f                	jmp    f01014a5 <strncpy+0x23>
		*dst++ = *src;
f0101496:	83 c2 01             	add    $0x1,%edx
f0101499:	0f b6 01             	movzbl (%ecx),%eax
f010149c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010149f:	80 39 01             	cmpb   $0x1,(%ecx)
f01014a2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014a5:	39 da                	cmp    %ebx,%edx
f01014a7:	75 ed                	jne    f0101496 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01014a9:	89 f0                	mov    %esi,%eax
f01014ab:	5b                   	pop    %ebx
f01014ac:	5e                   	pop    %esi
f01014ad:	5d                   	pop    %ebp
f01014ae:	c3                   	ret    

f01014af <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01014af:	55                   	push   %ebp
f01014b0:	89 e5                	mov    %esp,%ebp
f01014b2:	56                   	push   %esi
f01014b3:	53                   	push   %ebx
f01014b4:	8b 75 08             	mov    0x8(%ebp),%esi
f01014b7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014ba:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01014bd:	89 f0                	mov    %esi,%eax
f01014bf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01014c3:	85 c9                	test   %ecx,%ecx
f01014c5:	75 0b                	jne    f01014d2 <strlcpy+0x23>
f01014c7:	eb 1d                	jmp    f01014e6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01014c9:	83 c0 01             	add    $0x1,%eax
f01014cc:	83 c2 01             	add    $0x1,%edx
f01014cf:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01014d2:	39 d8                	cmp    %ebx,%eax
f01014d4:	74 0b                	je     f01014e1 <strlcpy+0x32>
f01014d6:	0f b6 0a             	movzbl (%edx),%ecx
f01014d9:	84 c9                	test   %cl,%cl
f01014db:	75 ec                	jne    f01014c9 <strlcpy+0x1a>
f01014dd:	89 c2                	mov    %eax,%edx
f01014df:	eb 02                	jmp    f01014e3 <strlcpy+0x34>
f01014e1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01014e3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01014e6:	29 f0                	sub    %esi,%eax
}
f01014e8:	5b                   	pop    %ebx
f01014e9:	5e                   	pop    %esi
f01014ea:	5d                   	pop    %ebp
f01014eb:	c3                   	ret    

f01014ec <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014ec:	55                   	push   %ebp
f01014ed:	89 e5                	mov    %esp,%ebp
f01014ef:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014f2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014f5:	eb 06                	jmp    f01014fd <strcmp+0x11>
		p++, q++;
f01014f7:	83 c1 01             	add    $0x1,%ecx
f01014fa:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014fd:	0f b6 01             	movzbl (%ecx),%eax
f0101500:	84 c0                	test   %al,%al
f0101502:	74 04                	je     f0101508 <strcmp+0x1c>
f0101504:	3a 02                	cmp    (%edx),%al
f0101506:	74 ef                	je     f01014f7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101508:	0f b6 c0             	movzbl %al,%eax
f010150b:	0f b6 12             	movzbl (%edx),%edx
f010150e:	29 d0                	sub    %edx,%eax
}
f0101510:	5d                   	pop    %ebp
f0101511:	c3                   	ret    

f0101512 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101512:	55                   	push   %ebp
f0101513:	89 e5                	mov    %esp,%ebp
f0101515:	53                   	push   %ebx
f0101516:	8b 45 08             	mov    0x8(%ebp),%eax
f0101519:	8b 55 0c             	mov    0xc(%ebp),%edx
f010151c:	89 c3                	mov    %eax,%ebx
f010151e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101521:	eb 06                	jmp    f0101529 <strncmp+0x17>
		n--, p++, q++;
f0101523:	83 c0 01             	add    $0x1,%eax
f0101526:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101529:	39 d8                	cmp    %ebx,%eax
f010152b:	74 15                	je     f0101542 <strncmp+0x30>
f010152d:	0f b6 08             	movzbl (%eax),%ecx
f0101530:	84 c9                	test   %cl,%cl
f0101532:	74 04                	je     f0101538 <strncmp+0x26>
f0101534:	3a 0a                	cmp    (%edx),%cl
f0101536:	74 eb                	je     f0101523 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101538:	0f b6 00             	movzbl (%eax),%eax
f010153b:	0f b6 12             	movzbl (%edx),%edx
f010153e:	29 d0                	sub    %edx,%eax
f0101540:	eb 05                	jmp    f0101547 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101542:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101547:	5b                   	pop    %ebx
f0101548:	5d                   	pop    %ebp
f0101549:	c3                   	ret    

f010154a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010154a:	55                   	push   %ebp
f010154b:	89 e5                	mov    %esp,%ebp
f010154d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101550:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101554:	eb 07                	jmp    f010155d <strchr+0x13>
		if (*s == c)
f0101556:	38 ca                	cmp    %cl,%dl
f0101558:	74 0f                	je     f0101569 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010155a:	83 c0 01             	add    $0x1,%eax
f010155d:	0f b6 10             	movzbl (%eax),%edx
f0101560:	84 d2                	test   %dl,%dl
f0101562:	75 f2                	jne    f0101556 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101564:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101569:	5d                   	pop    %ebp
f010156a:	c3                   	ret    

f010156b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010156b:	55                   	push   %ebp
f010156c:	89 e5                	mov    %esp,%ebp
f010156e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101571:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101575:	eb 07                	jmp    f010157e <strfind+0x13>
		if (*s == c)
f0101577:	38 ca                	cmp    %cl,%dl
f0101579:	74 0a                	je     f0101585 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010157b:	83 c0 01             	add    $0x1,%eax
f010157e:	0f b6 10             	movzbl (%eax),%edx
f0101581:	84 d2                	test   %dl,%dl
f0101583:	75 f2                	jne    f0101577 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101585:	5d                   	pop    %ebp
f0101586:	c3                   	ret    

f0101587 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101587:	55                   	push   %ebp
f0101588:	89 e5                	mov    %esp,%ebp
f010158a:	57                   	push   %edi
f010158b:	56                   	push   %esi
f010158c:	53                   	push   %ebx
f010158d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101590:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101593:	85 c9                	test   %ecx,%ecx
f0101595:	74 36                	je     f01015cd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101597:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010159d:	75 28                	jne    f01015c7 <memset+0x40>
f010159f:	f6 c1 03             	test   $0x3,%cl
f01015a2:	75 23                	jne    f01015c7 <memset+0x40>
		c &= 0xFF;
f01015a4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015a8:	89 d3                	mov    %edx,%ebx
f01015aa:	c1 e3 08             	shl    $0x8,%ebx
f01015ad:	89 d6                	mov    %edx,%esi
f01015af:	c1 e6 18             	shl    $0x18,%esi
f01015b2:	89 d0                	mov    %edx,%eax
f01015b4:	c1 e0 10             	shl    $0x10,%eax
f01015b7:	09 f0                	or     %esi,%eax
f01015b9:	09 c2                	or     %eax,%edx
f01015bb:	89 d0                	mov    %edx,%eax
f01015bd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01015bf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01015c2:	fc                   	cld    
f01015c3:	f3 ab                	rep stos %eax,%es:(%edi)
f01015c5:	eb 06                	jmp    f01015cd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015c7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015ca:	fc                   	cld    
f01015cb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015cd:	89 f8                	mov    %edi,%eax
f01015cf:	5b                   	pop    %ebx
f01015d0:	5e                   	pop    %esi
f01015d1:	5f                   	pop    %edi
f01015d2:	5d                   	pop    %ebp
f01015d3:	c3                   	ret    

f01015d4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015d4:	55                   	push   %ebp
f01015d5:	89 e5                	mov    %esp,%ebp
f01015d7:	57                   	push   %edi
f01015d8:	56                   	push   %esi
f01015d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01015dc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015df:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015e2:	39 c6                	cmp    %eax,%esi
f01015e4:	73 35                	jae    f010161b <memmove+0x47>
f01015e6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015e9:	39 d0                	cmp    %edx,%eax
f01015eb:	73 2e                	jae    f010161b <memmove+0x47>
		s += n;
		d += n;
f01015ed:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01015f0:	89 d6                	mov    %edx,%esi
f01015f2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015f4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015fa:	75 13                	jne    f010160f <memmove+0x3b>
f01015fc:	f6 c1 03             	test   $0x3,%cl
f01015ff:	75 0e                	jne    f010160f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101601:	83 ef 04             	sub    $0x4,%edi
f0101604:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101607:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010160a:	fd                   	std    
f010160b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010160d:	eb 09                	jmp    f0101618 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010160f:	83 ef 01             	sub    $0x1,%edi
f0101612:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101615:	fd                   	std    
f0101616:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101618:	fc                   	cld    
f0101619:	eb 1d                	jmp    f0101638 <memmove+0x64>
f010161b:	89 f2                	mov    %esi,%edx
f010161d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010161f:	f6 c2 03             	test   $0x3,%dl
f0101622:	75 0f                	jne    f0101633 <memmove+0x5f>
f0101624:	f6 c1 03             	test   $0x3,%cl
f0101627:	75 0a                	jne    f0101633 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101629:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010162c:	89 c7                	mov    %eax,%edi
f010162e:	fc                   	cld    
f010162f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101631:	eb 05                	jmp    f0101638 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101633:	89 c7                	mov    %eax,%edi
f0101635:	fc                   	cld    
f0101636:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101638:	5e                   	pop    %esi
f0101639:	5f                   	pop    %edi
f010163a:	5d                   	pop    %ebp
f010163b:	c3                   	ret    

f010163c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010163c:	55                   	push   %ebp
f010163d:	89 e5                	mov    %esp,%ebp
f010163f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101642:	8b 45 10             	mov    0x10(%ebp),%eax
f0101645:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101649:	8b 45 0c             	mov    0xc(%ebp),%eax
f010164c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101650:	8b 45 08             	mov    0x8(%ebp),%eax
f0101653:	89 04 24             	mov    %eax,(%esp)
f0101656:	e8 79 ff ff ff       	call   f01015d4 <memmove>
}
f010165b:	c9                   	leave  
f010165c:	c3                   	ret    

f010165d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010165d:	55                   	push   %ebp
f010165e:	89 e5                	mov    %esp,%ebp
f0101660:	56                   	push   %esi
f0101661:	53                   	push   %ebx
f0101662:	8b 55 08             	mov    0x8(%ebp),%edx
f0101665:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101668:	89 d6                	mov    %edx,%esi
f010166a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010166d:	eb 1a                	jmp    f0101689 <memcmp+0x2c>
		if (*s1 != *s2)
f010166f:	0f b6 02             	movzbl (%edx),%eax
f0101672:	0f b6 19             	movzbl (%ecx),%ebx
f0101675:	38 d8                	cmp    %bl,%al
f0101677:	74 0a                	je     f0101683 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101679:	0f b6 c0             	movzbl %al,%eax
f010167c:	0f b6 db             	movzbl %bl,%ebx
f010167f:	29 d8                	sub    %ebx,%eax
f0101681:	eb 0f                	jmp    f0101692 <memcmp+0x35>
		s1++, s2++;
f0101683:	83 c2 01             	add    $0x1,%edx
f0101686:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101689:	39 f2                	cmp    %esi,%edx
f010168b:	75 e2                	jne    f010166f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010168d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101692:	5b                   	pop    %ebx
f0101693:	5e                   	pop    %esi
f0101694:	5d                   	pop    %ebp
f0101695:	c3                   	ret    

f0101696 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101696:	55                   	push   %ebp
f0101697:	89 e5                	mov    %esp,%ebp
f0101699:	8b 45 08             	mov    0x8(%ebp),%eax
f010169c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010169f:	89 c2                	mov    %eax,%edx
f01016a1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016a4:	eb 07                	jmp    f01016ad <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016a6:	38 08                	cmp    %cl,(%eax)
f01016a8:	74 07                	je     f01016b1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01016aa:	83 c0 01             	add    $0x1,%eax
f01016ad:	39 d0                	cmp    %edx,%eax
f01016af:	72 f5                	jb     f01016a6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01016b1:	5d                   	pop    %ebp
f01016b2:	c3                   	ret    

f01016b3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016b3:	55                   	push   %ebp
f01016b4:	89 e5                	mov    %esp,%ebp
f01016b6:	57                   	push   %edi
f01016b7:	56                   	push   %esi
f01016b8:	53                   	push   %ebx
f01016b9:	8b 55 08             	mov    0x8(%ebp),%edx
f01016bc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016bf:	eb 03                	jmp    f01016c4 <strtol+0x11>
		s++;
f01016c1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016c4:	0f b6 0a             	movzbl (%edx),%ecx
f01016c7:	80 f9 09             	cmp    $0x9,%cl
f01016ca:	74 f5                	je     f01016c1 <strtol+0xe>
f01016cc:	80 f9 20             	cmp    $0x20,%cl
f01016cf:	74 f0                	je     f01016c1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01016d1:	80 f9 2b             	cmp    $0x2b,%cl
f01016d4:	75 0a                	jne    f01016e0 <strtol+0x2d>
		s++;
f01016d6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01016d9:	bf 00 00 00 00       	mov    $0x0,%edi
f01016de:	eb 11                	jmp    f01016f1 <strtol+0x3e>
f01016e0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01016e5:	80 f9 2d             	cmp    $0x2d,%cl
f01016e8:	75 07                	jne    f01016f1 <strtol+0x3e>
		s++, neg = 1;
f01016ea:	8d 52 01             	lea    0x1(%edx),%edx
f01016ed:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016f1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01016f6:	75 15                	jne    f010170d <strtol+0x5a>
f01016f8:	80 3a 30             	cmpb   $0x30,(%edx)
f01016fb:	75 10                	jne    f010170d <strtol+0x5a>
f01016fd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101701:	75 0a                	jne    f010170d <strtol+0x5a>
		s += 2, base = 16;
f0101703:	83 c2 02             	add    $0x2,%edx
f0101706:	b8 10 00 00 00       	mov    $0x10,%eax
f010170b:	eb 10                	jmp    f010171d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010170d:	85 c0                	test   %eax,%eax
f010170f:	75 0c                	jne    f010171d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101711:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101713:	80 3a 30             	cmpb   $0x30,(%edx)
f0101716:	75 05                	jne    f010171d <strtol+0x6a>
		s++, base = 8;
f0101718:	83 c2 01             	add    $0x1,%edx
f010171b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010171d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101722:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101725:	0f b6 0a             	movzbl (%edx),%ecx
f0101728:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010172b:	89 f0                	mov    %esi,%eax
f010172d:	3c 09                	cmp    $0x9,%al
f010172f:	77 08                	ja     f0101739 <strtol+0x86>
			dig = *s - '0';
f0101731:	0f be c9             	movsbl %cl,%ecx
f0101734:	83 e9 30             	sub    $0x30,%ecx
f0101737:	eb 20                	jmp    f0101759 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101739:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010173c:	89 f0                	mov    %esi,%eax
f010173e:	3c 19                	cmp    $0x19,%al
f0101740:	77 08                	ja     f010174a <strtol+0x97>
			dig = *s - 'a' + 10;
f0101742:	0f be c9             	movsbl %cl,%ecx
f0101745:	83 e9 57             	sub    $0x57,%ecx
f0101748:	eb 0f                	jmp    f0101759 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010174a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010174d:	89 f0                	mov    %esi,%eax
f010174f:	3c 19                	cmp    $0x19,%al
f0101751:	77 16                	ja     f0101769 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101753:	0f be c9             	movsbl %cl,%ecx
f0101756:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101759:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010175c:	7d 0f                	jge    f010176d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010175e:	83 c2 01             	add    $0x1,%edx
f0101761:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101765:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101767:	eb bc                	jmp    f0101725 <strtol+0x72>
f0101769:	89 d8                	mov    %ebx,%eax
f010176b:	eb 02                	jmp    f010176f <strtol+0xbc>
f010176d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010176f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101773:	74 05                	je     f010177a <strtol+0xc7>
		*endptr = (char *) s;
f0101775:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101778:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010177a:	f7 d8                	neg    %eax
f010177c:	85 ff                	test   %edi,%edi
f010177e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101781:	5b                   	pop    %ebx
f0101782:	5e                   	pop    %esi
f0101783:	5f                   	pop    %edi
f0101784:	5d                   	pop    %ebp
f0101785:	c3                   	ret    
f0101786:	66 90                	xchg   %ax,%ax
f0101788:	66 90                	xchg   %ax,%ax
f010178a:	66 90                	xchg   %ax,%ax
f010178c:	66 90                	xchg   %ax,%ax
f010178e:	66 90                	xchg   %ax,%ax

f0101790 <__udivdi3>:
f0101790:	55                   	push   %ebp
f0101791:	57                   	push   %edi
f0101792:	56                   	push   %esi
f0101793:	83 ec 0c             	sub    $0xc,%esp
f0101796:	8b 44 24 28          	mov    0x28(%esp),%eax
f010179a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010179e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01017a2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01017a6:	85 c0                	test   %eax,%eax
f01017a8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017ac:	89 ea                	mov    %ebp,%edx
f01017ae:	89 0c 24             	mov    %ecx,(%esp)
f01017b1:	75 2d                	jne    f01017e0 <__udivdi3+0x50>
f01017b3:	39 e9                	cmp    %ebp,%ecx
f01017b5:	77 61                	ja     f0101818 <__udivdi3+0x88>
f01017b7:	85 c9                	test   %ecx,%ecx
f01017b9:	89 ce                	mov    %ecx,%esi
f01017bb:	75 0b                	jne    f01017c8 <__udivdi3+0x38>
f01017bd:	b8 01 00 00 00       	mov    $0x1,%eax
f01017c2:	31 d2                	xor    %edx,%edx
f01017c4:	f7 f1                	div    %ecx
f01017c6:	89 c6                	mov    %eax,%esi
f01017c8:	31 d2                	xor    %edx,%edx
f01017ca:	89 e8                	mov    %ebp,%eax
f01017cc:	f7 f6                	div    %esi
f01017ce:	89 c5                	mov    %eax,%ebp
f01017d0:	89 f8                	mov    %edi,%eax
f01017d2:	f7 f6                	div    %esi
f01017d4:	89 ea                	mov    %ebp,%edx
f01017d6:	83 c4 0c             	add    $0xc,%esp
f01017d9:	5e                   	pop    %esi
f01017da:	5f                   	pop    %edi
f01017db:	5d                   	pop    %ebp
f01017dc:	c3                   	ret    
f01017dd:	8d 76 00             	lea    0x0(%esi),%esi
f01017e0:	39 e8                	cmp    %ebp,%eax
f01017e2:	77 24                	ja     f0101808 <__udivdi3+0x78>
f01017e4:	0f bd e8             	bsr    %eax,%ebp
f01017e7:	83 f5 1f             	xor    $0x1f,%ebp
f01017ea:	75 3c                	jne    f0101828 <__udivdi3+0x98>
f01017ec:	8b 74 24 04          	mov    0x4(%esp),%esi
f01017f0:	39 34 24             	cmp    %esi,(%esp)
f01017f3:	0f 86 9f 00 00 00    	jbe    f0101898 <__udivdi3+0x108>
f01017f9:	39 d0                	cmp    %edx,%eax
f01017fb:	0f 82 97 00 00 00    	jb     f0101898 <__udivdi3+0x108>
f0101801:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101808:	31 d2                	xor    %edx,%edx
f010180a:	31 c0                	xor    %eax,%eax
f010180c:	83 c4 0c             	add    $0xc,%esp
f010180f:	5e                   	pop    %esi
f0101810:	5f                   	pop    %edi
f0101811:	5d                   	pop    %ebp
f0101812:	c3                   	ret    
f0101813:	90                   	nop
f0101814:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101818:	89 f8                	mov    %edi,%eax
f010181a:	f7 f1                	div    %ecx
f010181c:	31 d2                	xor    %edx,%edx
f010181e:	83 c4 0c             	add    $0xc,%esp
f0101821:	5e                   	pop    %esi
f0101822:	5f                   	pop    %edi
f0101823:	5d                   	pop    %ebp
f0101824:	c3                   	ret    
f0101825:	8d 76 00             	lea    0x0(%esi),%esi
f0101828:	89 e9                	mov    %ebp,%ecx
f010182a:	8b 3c 24             	mov    (%esp),%edi
f010182d:	d3 e0                	shl    %cl,%eax
f010182f:	89 c6                	mov    %eax,%esi
f0101831:	b8 20 00 00 00       	mov    $0x20,%eax
f0101836:	29 e8                	sub    %ebp,%eax
f0101838:	89 c1                	mov    %eax,%ecx
f010183a:	d3 ef                	shr    %cl,%edi
f010183c:	89 e9                	mov    %ebp,%ecx
f010183e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101842:	8b 3c 24             	mov    (%esp),%edi
f0101845:	09 74 24 08          	or     %esi,0x8(%esp)
f0101849:	89 d6                	mov    %edx,%esi
f010184b:	d3 e7                	shl    %cl,%edi
f010184d:	89 c1                	mov    %eax,%ecx
f010184f:	89 3c 24             	mov    %edi,(%esp)
f0101852:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101856:	d3 ee                	shr    %cl,%esi
f0101858:	89 e9                	mov    %ebp,%ecx
f010185a:	d3 e2                	shl    %cl,%edx
f010185c:	89 c1                	mov    %eax,%ecx
f010185e:	d3 ef                	shr    %cl,%edi
f0101860:	09 d7                	or     %edx,%edi
f0101862:	89 f2                	mov    %esi,%edx
f0101864:	89 f8                	mov    %edi,%eax
f0101866:	f7 74 24 08          	divl   0x8(%esp)
f010186a:	89 d6                	mov    %edx,%esi
f010186c:	89 c7                	mov    %eax,%edi
f010186e:	f7 24 24             	mull   (%esp)
f0101871:	39 d6                	cmp    %edx,%esi
f0101873:	89 14 24             	mov    %edx,(%esp)
f0101876:	72 30                	jb     f01018a8 <__udivdi3+0x118>
f0101878:	8b 54 24 04          	mov    0x4(%esp),%edx
f010187c:	89 e9                	mov    %ebp,%ecx
f010187e:	d3 e2                	shl    %cl,%edx
f0101880:	39 c2                	cmp    %eax,%edx
f0101882:	73 05                	jae    f0101889 <__udivdi3+0xf9>
f0101884:	3b 34 24             	cmp    (%esp),%esi
f0101887:	74 1f                	je     f01018a8 <__udivdi3+0x118>
f0101889:	89 f8                	mov    %edi,%eax
f010188b:	31 d2                	xor    %edx,%edx
f010188d:	e9 7a ff ff ff       	jmp    f010180c <__udivdi3+0x7c>
f0101892:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101898:	31 d2                	xor    %edx,%edx
f010189a:	b8 01 00 00 00       	mov    $0x1,%eax
f010189f:	e9 68 ff ff ff       	jmp    f010180c <__udivdi3+0x7c>
f01018a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018a8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01018ab:	31 d2                	xor    %edx,%edx
f01018ad:	83 c4 0c             	add    $0xc,%esp
f01018b0:	5e                   	pop    %esi
f01018b1:	5f                   	pop    %edi
f01018b2:	5d                   	pop    %ebp
f01018b3:	c3                   	ret    
f01018b4:	66 90                	xchg   %ax,%ax
f01018b6:	66 90                	xchg   %ax,%ax
f01018b8:	66 90                	xchg   %ax,%ax
f01018ba:	66 90                	xchg   %ax,%ax
f01018bc:	66 90                	xchg   %ax,%ax
f01018be:	66 90                	xchg   %ax,%ax

f01018c0 <__umoddi3>:
f01018c0:	55                   	push   %ebp
f01018c1:	57                   	push   %edi
f01018c2:	56                   	push   %esi
f01018c3:	83 ec 14             	sub    $0x14,%esp
f01018c6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01018ca:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01018ce:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01018d2:	89 c7                	mov    %eax,%edi
f01018d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018d8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01018dc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01018e0:	89 34 24             	mov    %esi,(%esp)
f01018e3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018e7:	85 c0                	test   %eax,%eax
f01018e9:	89 c2                	mov    %eax,%edx
f01018eb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018ef:	75 17                	jne    f0101908 <__umoddi3+0x48>
f01018f1:	39 fe                	cmp    %edi,%esi
f01018f3:	76 4b                	jbe    f0101940 <__umoddi3+0x80>
f01018f5:	89 c8                	mov    %ecx,%eax
f01018f7:	89 fa                	mov    %edi,%edx
f01018f9:	f7 f6                	div    %esi
f01018fb:	89 d0                	mov    %edx,%eax
f01018fd:	31 d2                	xor    %edx,%edx
f01018ff:	83 c4 14             	add    $0x14,%esp
f0101902:	5e                   	pop    %esi
f0101903:	5f                   	pop    %edi
f0101904:	5d                   	pop    %ebp
f0101905:	c3                   	ret    
f0101906:	66 90                	xchg   %ax,%ax
f0101908:	39 f8                	cmp    %edi,%eax
f010190a:	77 54                	ja     f0101960 <__umoddi3+0xa0>
f010190c:	0f bd e8             	bsr    %eax,%ebp
f010190f:	83 f5 1f             	xor    $0x1f,%ebp
f0101912:	75 5c                	jne    f0101970 <__umoddi3+0xb0>
f0101914:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101918:	39 3c 24             	cmp    %edi,(%esp)
f010191b:	0f 87 e7 00 00 00    	ja     f0101a08 <__umoddi3+0x148>
f0101921:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101925:	29 f1                	sub    %esi,%ecx
f0101927:	19 c7                	sbb    %eax,%edi
f0101929:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010192d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101931:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101935:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101939:	83 c4 14             	add    $0x14,%esp
f010193c:	5e                   	pop    %esi
f010193d:	5f                   	pop    %edi
f010193e:	5d                   	pop    %ebp
f010193f:	c3                   	ret    
f0101940:	85 f6                	test   %esi,%esi
f0101942:	89 f5                	mov    %esi,%ebp
f0101944:	75 0b                	jne    f0101951 <__umoddi3+0x91>
f0101946:	b8 01 00 00 00       	mov    $0x1,%eax
f010194b:	31 d2                	xor    %edx,%edx
f010194d:	f7 f6                	div    %esi
f010194f:	89 c5                	mov    %eax,%ebp
f0101951:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101955:	31 d2                	xor    %edx,%edx
f0101957:	f7 f5                	div    %ebp
f0101959:	89 c8                	mov    %ecx,%eax
f010195b:	f7 f5                	div    %ebp
f010195d:	eb 9c                	jmp    f01018fb <__umoddi3+0x3b>
f010195f:	90                   	nop
f0101960:	89 c8                	mov    %ecx,%eax
f0101962:	89 fa                	mov    %edi,%edx
f0101964:	83 c4 14             	add    $0x14,%esp
f0101967:	5e                   	pop    %esi
f0101968:	5f                   	pop    %edi
f0101969:	5d                   	pop    %ebp
f010196a:	c3                   	ret    
f010196b:	90                   	nop
f010196c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101970:	8b 04 24             	mov    (%esp),%eax
f0101973:	be 20 00 00 00       	mov    $0x20,%esi
f0101978:	89 e9                	mov    %ebp,%ecx
f010197a:	29 ee                	sub    %ebp,%esi
f010197c:	d3 e2                	shl    %cl,%edx
f010197e:	89 f1                	mov    %esi,%ecx
f0101980:	d3 e8                	shr    %cl,%eax
f0101982:	89 e9                	mov    %ebp,%ecx
f0101984:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101988:	8b 04 24             	mov    (%esp),%eax
f010198b:	09 54 24 04          	or     %edx,0x4(%esp)
f010198f:	89 fa                	mov    %edi,%edx
f0101991:	d3 e0                	shl    %cl,%eax
f0101993:	89 f1                	mov    %esi,%ecx
f0101995:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101999:	8b 44 24 10          	mov    0x10(%esp),%eax
f010199d:	d3 ea                	shr    %cl,%edx
f010199f:	89 e9                	mov    %ebp,%ecx
f01019a1:	d3 e7                	shl    %cl,%edi
f01019a3:	89 f1                	mov    %esi,%ecx
f01019a5:	d3 e8                	shr    %cl,%eax
f01019a7:	89 e9                	mov    %ebp,%ecx
f01019a9:	09 f8                	or     %edi,%eax
f01019ab:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01019af:	f7 74 24 04          	divl   0x4(%esp)
f01019b3:	d3 e7                	shl    %cl,%edi
f01019b5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01019b9:	89 d7                	mov    %edx,%edi
f01019bb:	f7 64 24 08          	mull   0x8(%esp)
f01019bf:	39 d7                	cmp    %edx,%edi
f01019c1:	89 c1                	mov    %eax,%ecx
f01019c3:	89 14 24             	mov    %edx,(%esp)
f01019c6:	72 2c                	jb     f01019f4 <__umoddi3+0x134>
f01019c8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01019cc:	72 22                	jb     f01019f0 <__umoddi3+0x130>
f01019ce:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01019d2:	29 c8                	sub    %ecx,%eax
f01019d4:	19 d7                	sbb    %edx,%edi
f01019d6:	89 e9                	mov    %ebp,%ecx
f01019d8:	89 fa                	mov    %edi,%edx
f01019da:	d3 e8                	shr    %cl,%eax
f01019dc:	89 f1                	mov    %esi,%ecx
f01019de:	d3 e2                	shl    %cl,%edx
f01019e0:	89 e9                	mov    %ebp,%ecx
f01019e2:	d3 ef                	shr    %cl,%edi
f01019e4:	09 d0                	or     %edx,%eax
f01019e6:	89 fa                	mov    %edi,%edx
f01019e8:	83 c4 14             	add    $0x14,%esp
f01019eb:	5e                   	pop    %esi
f01019ec:	5f                   	pop    %edi
f01019ed:	5d                   	pop    %ebp
f01019ee:	c3                   	ret    
f01019ef:	90                   	nop
f01019f0:	39 d7                	cmp    %edx,%edi
f01019f2:	75 da                	jne    f01019ce <__umoddi3+0x10e>
f01019f4:	8b 14 24             	mov    (%esp),%edx
f01019f7:	89 c1                	mov    %eax,%ecx
f01019f9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01019fd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101a01:	eb cb                	jmp    f01019ce <__umoddi3+0x10e>
f0101a03:	90                   	nop
f0101a04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a08:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101a0c:	0f 82 0f ff ff ff    	jb     f0101921 <__umoddi3+0x61>
f0101a12:	e9 1a ff ff ff       	jmp    f0101931 <__umoddi3+0x71>
