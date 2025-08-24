;Program X-Meter Version 1.0.8
;MCU    =   AT89S52
;X-TAL  =   22.118 MHz
;Ver 1.01 Date  25/11/2006 {turn off all warning lamp when switch to sleep mode}}
;Ver 1.02 Date  10/12/2006 {auto sleep and auto activate}
;Ver 1.03 Date  31/12/2006 {turn off all warning lamp when leave meter mode/DTC additional message/CLEAR MIL}
;Ver 1.04 Date  22/04/2007 {No. of DTC bug fixed, Read DTCs,HO2S voltage display bug fixed}
;Ver 1.05 Date 05/01/2013 {PID23 Fuel Rail Pressure Added, Auto Backlight added}
;Ver 1.06 Date 23/05/2015 {Mode 22 PID 1E1C Transmission Fluid Temp} 
;Ver 1.07 Date 22/02/2016 {Transmission Fluid Temp bug fixed}
;Ver 1.08 Date 25/11/2022 {Transmission Fluid Temp bug fixed + add more pid}
;==============================================
;Pin Configuration
LCDDATA	EQU	P0		;LCD data Line
;Port1
MOSI	BIT	P1.5		;ISP Data Out
MISO	BIT	P1.6		;ISP Data In
SCK	BIT	P1.7		;ISP Clock
;Port 2
RW	BIT	P2.0		;LCD 0 = Read  1 = write
RS	BIT	P2.1		;LCD 0 = Instruction 1 = Data
EN	BIT	P2.2		;LCD clock High to Low 
BL	BIT	P2.3		;LCD Back Light 0 = On, 1 = OFF
BUZZER	BIT	P2.4		;Buzzer Bit 0= On, 1 = OFF
EEPSDA	BIT	P2.5		;EEprom Data Line
EEPSCL	BIT	P2.6		;EEprom Clock Line
EEPWP	BIT	P2.7		;EEprom write Protect 0 = Disable, 1= Write Protect
;now use bit P2.7 as Auto backlight input with LDR circuit
;Port3   P3.0 & P3.1 Reserved as Serial Port
BTNMENU	BIT	P3.2		;Menu button
BTNBL	BIT	P3.3		;Backlight toggle switch
BTNUP	BIT	P3.4		;UP button
BTNDN	BIT	P3.5		;Down button
LEDUP	BIT	P3.6		;Upper Warning  LED 0 = On, 1 = OFF		
LEDDN	BIT	P3.7		;Lower  Warning  LED 0 = On, 1 = OFF		
;Port1   Reserved as extentsion & ISP
;Internal Ram
PID1	EQU	08h		;PID1 mode
PID2	EQU	09h		;PID2 mode
PIDTURN	EQU	0Ah		;check which PID will be sent to ELM
WRADDL1	EQU	0Bh		;LCD write address for calculated value line1
WRADDL2	EQU	0Ch		;LCD write address for calculated value line2
B1	EQU	0Dh		;address for Byte1
B2	EQU	0Eh		;address for Byte2
RESULTLEN	EQU	0Fh	;keep length of result
CONFIG	EQU	10h		;current config      
;bit3 = PID warning light (0-off,1-on) ,bit 2 = F/C mode(0=inst/1=avr) , bit1 =beep(0-off,1-on), bit0=backlight(0-off,1-on)
;bit4 = Auto sleep mode (0-off,1-on)
TEMP1	EQU	11h		;general ram use
TEMP2	EQU	12h		;general ram use
TEMP3	EQU	13h		;general ram use
EEPERR	EQU	14h		;EEPROM I2C Error
FCPTR	EQU	15h		;IRAM pointer for F/C 80h-FFh data logging
LIMITCHK1	EQU	16h	;address for keep limit PID load from eeprom
LIMITCHK2	EQU	17h	;address for keep limit PID load from eeprom
SLEEPCNT	EQU	18h	;sleep mode counter
AUTOBLSTAT	EQU	19h	;Hold Autobacklight status for checking
BUFFER	EQU	20h		;Message Buffer
;Stack Pointer at 60h up to 7Fh
;Special Function Register
WDTRST	EQU	0A6h		;SFR address for Watchdog Timer Register
;EEPROM address assignment
ECONFIG	EQU	00h		;Configuration same as CONFIG
EPID1	EQU	01h
EPID2	EQU	02h
;04h-4Fh  Reserved for Warning Lamp in each PID no.

;PID04 CAL Engine Load ---%"	[90 = 0E5h]
;PID05 Coolant Temp: --- " 	[97 = 089h]
;PID06 S-T Fuel Trim1 --- %" 	[+/- 10 = 08Eh]
;PID07 L-T Fuel Trim1 --- %"	[+/- 10 = 08Eh]
;PID0A Fuel Pressure ---kPa"  	[ 250 = FAh]lowerlimit*
;PID0B MAN Air Press ---kPa"  	[101 = 65h]
;PID0C ENG Speed: ---- RPM " [6500 = 66h]
;PID0D VEH Speed: --- km/h " 	[160 = A0h]
;PID0E IGN ADV Timing: ---" 	[+/- 27.5 = FFh]
;PID0F Intake Air Temp --" 	[90c = 82h]
;PID10 Air Flow ---.- g/sec"	[50.0g/s = 14h]
;PID11 Throttle Pos: --- %  "	[80%  = CCh]
;PID14 Front HO2S Volt -.--" 	[0.21 V= 2Ah] lowerlimit*
;PID15 Rear  HO2S Volt -.--"	[0.21 V= 2Ah] lowerlimit*
;PID23 Rail Pressure ---MPa"      ((A*256)+B) /100
;PID2C Commanded EGR: --- %" [100% = FFh]
;PID2D EGR Error: --- %    "	[100% = FFh]
;PID2E CMD Evap Purge --- %"   [100% = FFh]	
;PID2F Fuel Level: --- %   "	[5%     =  0Ch] lower limit*
;PID33 Baro Pressure ---kPa"	[102 = 66h]
;PID3C CAT 1 Temp: ---.- "	[700c = 1Bh]
;PID3D CAT 2 Temp: ---.- "	[700c = 1Bh]
;PID42:PCM Voltage: --.-- V"	[11.0 = 2Bh] lowerlimit*
;PID43 ABS Engine Load ---%"	[90 = 0E5h]
;PID44 CMD EQV Ratio: -.--   "  [not sure = FFh]
;PID45 REL Throt Pos: --- %"	[90 = 0E5h]
;PID46 AMB Air Temp: --- "	[40 = 50h]
;PID5C ENG Oil Temp: --- "  []
;TFT: DB "Trans Temp: ---.- " [100 = 64h]

;*******************************************
;LCD Commands Write parameter   
;MOV A = parameter then CALL LCD_CMD_WR
LCD_CLS	EQU	01
LCD_HOME	EQU	02
LCD_SETMODE	EQU	04	;+I/D  S
;I/D  = 0 Cursor&DDRAM  Decrement  , I/D = 1 Cursor&DDRAM Increment
;S   = 0   Cursor Move as I/D, S =1  insert charactor
LCD_SETVISIBLE	EQU	08	;+ D C B
;D = 0 Off display ,D = 1 On display
;C = 0 Off Cur sor , C = 1 On cursor
;B = 0 Blink Off    ,  B = 1 Blink On
LCD_SHIFT	EQU	16	; + S/C  R/L  x  x
;S/C = 0 move cursor as R/L  1 position
;S/C = 1 move charactor as R/L 1 column on every line
;R/L = 0 Left direction, R/L = 1 Right direction
LCD_SETFUNC	EQU	32	; + DL  N  F  x  x
;DL = 0  4 bit mode , DL = 1  8 bit mode
;N = 0  1/8 Duty   ,N = 1 1/16 duty
;F = 0   5x7 dot,   F = 1  5x10 dot
LCD_SETCGADDR	EQU	64	; + address  upto 16 data
LCD_SETDDADDR	EQU	128	; + address
;Program Start Address  ================
ORG	0000h
;*****RESET START***************************
RES:
	MOV	R0, #7FH	;POWER UP CLEAR 61-7FH
RES1:
	MOV	@R0, #0
	DEC	R0
	CJNE	R0, #00H, RES1	;Clear IRAM Adress 00h-7Fh = 0
	MOV	B, #0		;CLEAR SYSTEM FLAG
	MOV	SP, #80h	;SET STACK point to IRAM (not duplicate)
;Serial Port initialize
	MOV	PCON, #80H	;1000000
	MOV	TMOD, #22H	;TIMER1 MODE2
	MOV	TH1, #0FDH	;38400 bps
	MOV	SCON, #52H	;SERIAL 8 BIT UART MODE
	SETB	TR1		;TIMER1 ON
	CLR	ES		;no interrupt
;Default  Internal RAM if EEPROM Error
	MOV	PID1, #04h	;default PID1
	MOV	PID2, #11h	;default PID2
	MOV	PIDTURN, #01h	;set to PID1 current msg
	MOV	CONFIG, #00000110b	;beep on & backlight off , Instant F/C,Warning Lamp ON,auto sleep off
	MOV	FCPTR, #79h	;F/C pointer point to 79h
	MOV	SLEEPCNT, #24h	;Reset Sleep mode counter
;Initial Port
	CLR	P2
	SETB	P3
;MOV	P2,#00010000b	;clear port 2 for LCD  except buzzer to OFF
;MOV	P3,#0FFh		;Extend Port
;SETB	EEPWP		;EEPROM Write Protect enable (unused now)
	CLR	BL		;turn BL on
;addition here
;===========================
;Load CGRAM
	MOV	A, #LCD_SETCGADDR+0	;set CDRAM address
	CALL	WRCMD
	MOV	DPTR, #CGUL
	CALL	WRSTR		;write 3 char in CGRAM  00
	MOV	DPTR, #CGUM
	CALL	WRSTR		;write 3 char in CGRAM  01
	MOV	DPTR, #CGUR
	CALL	WRSTR		;write 3 char in CGRAM  02
	MOV	DPTR, #CGLL
	CALL	WRSTR		;write 3 char in CGRAM  03
	MOV	DPTR, #CGLM
	CALL	WRSTR		;write 3 char in CGRAM  04
	MOV	DPTR, #CGLR
	CALL	WRSTR		;write 3 char in CGRAM  05h
	MOV	DPTR, #CGDegC	;Load degree c symbol
	CALL	WRSTR		;write degree c symbol in CGRAM  06h
	MOV	DPTR, #CGDegF	;Load degree f symbol
	CALL	WRSTR		;write degree f symbol in CGRAM 07h

;add more here
;==================================
;LCD Initialize
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETFUNC+11000b
	CALL	WRCMD
	MOV	A, #LCD_SETVISIBLE+100b	; display on + nocursor + noblink
	CALL	WRCMD
	MOV	A, #LCD_SHIFT+0000b
	CALL	WRCMD
	MOV	A, #LCD_SETMODE+11b	;Left scroll
	CALL	WRCMD
;==============================
;LCD display title
	MOV	A, #LCD_SETDDADDR+00	;Line 1   OBDII X-METER V1
	CALL	WRCMD
	MOV	DPTR, #TITLE1	;OBDII X-METER V1
	CALL	WRSCR
	MOV	A, #LCD_SETDDADDR+40h	;Line2
	CALL	WRCMD
	MOV	DPTR, #TITLE2	;---------------------------
	CALL	WRSCR
;------------
	MOV	A, #LCD_SETMODE+10b	;Normal Right Scroll
	CALL	WRCMD
;======= Set Limitted Value Mode
	JB	BTNMENU, UPGRADE	;by pass Limitted Value 
	CALL	SOUND_BEEP
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETDDADDR+0	;Line 1
	CALL	WRCMD
	MOV	DPTR, #LIMITMSG	;Set limit message
	CALL	WRSTR
	MOV	A, #LCD_SETDDADDR+40h	;Line 2
	CALL	WRCMD
	MOV	DPTR, #UGFIRM2	;Waiting connection.
	CALL	WRSTR
	MOV	A, #LCD_SETVISIBLE+101b	; display on + nocursor + blinking
	CALL	WRCMD
	CLR	MISO		;set PIN checking to tell UPDATER xmeter is ready
	CLR	SCK		;set Low SCK for updater detect (X-Meter check Updater Start)
	JB	BTNBL, $+6	;toggle back light
	CALL	BACKLIGHT
	JNB	SCK, $-6	;if SCK is set hi else back to Updater
	MOV	A, #LCD_SETDDADDR+40h	;Line 2
	CALL	WRCMD
	MOV	DPTR, #UGFIRM3	;Now Loading...
	CALL	WRSTR
;add eeprom writing code  here
	MOV	R0, #01h	;start writing address (00h is reserved as CONFIG)
LIMITREAD:
	MOV	A, #00h
	MOV	R7, #08h
READ8BIT:
	JNB	SCK, $		;Wait CLK Hi
;read data 1 bit
	MOV	C, MOSI
	RLC	A
	SETB	MISO		;tell Updater that 1 bit read
	JB	SCK, $		;CLK Low end 1byte
	CLR	MISO
	DJNZ	R7, READ8BIT
;MOV	R0,address
	MOV	R1, A
	CALL	IPW		;write EEPROM 1 byte
	INC	R0		;next EEPROM address
	CJNE	R0, #080h, LIMITREAD	;If address = 128 then exit
	MOV	A, #LCD_SETDDADDR+40h	;Line 2
	CALL	WRCMD
	MOV	DPTR, #LIMITFIN	;Setting complete...
	CALL	WRSTR
	CALL	SOUND_BEEP	;finish
;======= Firmware Upgrade Mode
UPGRADE:
	JB	BTNUP, CHECKING	;by pass firmware upgrade
	JB	BTNDN, CHECKING
	CALL	SOUND_BEEP
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETDDADDR+0	;Line 1
	CALL	WRCMD
	MOV	DPTR, #UGFIRM1	;Upgrade Fimrware
	CALL	WRSTR
	MOV	A, #LCD_SETDDADDR+40h	;Line 2
	CALL	WRCMD
	MOV	DPTR, #UGFIRM2	;Waiting connection.
	CALL	WRSTR
	MOV	A, #LCD_SETVISIBLE+101b	; display on + nocursor + blinking
	CALL	WRCMD
	CLR	MISO		;set PIN checking for Upgrade firmwrae MISO (Updater Check X-Meter)
	CLR	SCK		;set Low SCK for updater detect (X-Meter check Updater Start)
	JB	BTNBL, $+6	;toggle back light
	CALL	BACKLIGHT
	JNB	SCK, $-6	;if SCK is set hi else back to Updater
	MOV	A, #LCD_SETDDADDR+40h	;Line 2
	CALL	WRCMD
	MOV	DPTR, #UGFIRM3	;Now Loading...
	CALL	WRSTR
	JMP	$		;Loop forever tl finish Upgrade
;Checking system
CHECKING:
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	CLR	LEDUP		;turn off LED
	CLR	LEDDN
	MOV	A, #LCD_CLS	;clear screen once
	CALL	WRCMD
	CALL	DEL100m
;****************Check illegal firmware modified
	CALL	SOUND_TRIG
	MOV	A, #LCD_SETDDADDR+0	;Line 1
	CALL	WRCMD
	MOV	DPTR, #TITLE3	;by Jerry@Thaimazda3  check illegal copy
	CALL	WRSTR
	MOV	A, #LCD_SETVISIBLE+101b	; display on + nocursor + blinking
	CALL	WRCMD
;===============================
;ELM327 Initialize message
	MOV	DPTR, #SERINIT1
	CALL	SBLOCK
	CALL	DEL100m
	MOV	DPTR, #SERINIT2
	CALL	SBLOCK
	CALL	DEL100m
	MOV	DPTR, #SERINIT3
	CALL	SBLOCK
	CALL	DEL100m
	MOV	DPTR, #SERINIT4
	CALL	SBLOCK
	CALL	DEL100m
	MOV	DPTR, #SERINIT5
	CALL	SBLOCK
	CALL	DEL100m

;========= Check CAN connection =====================
TRYCAN:				;OK and UNABLE TO CONNECT
	CLR	RI		;clear SBUF interrupt
	MOV	A, #LCD_SETDDADDR+40h	;Line2
	CALL	WRCMD
	MOV	DPTR, #NODATA	;clear LCD line2
	CALL	WRSTR
	MOV	A, #LCD_SETDDADDR+40h	;Line2
	CALL	WRCMD
	MOV	DPTR, #CHKCAN	;send 0100 to ELM327
	CALL	SBLOCK
	MOV	A, #3Eh		;send ">" first
TRYCAN1:
	CALL	WRCHAR		;write > to LCD & data receive by RBYTE
	CALL	RBYTE		;Receive "SEARCHING...."
	CJNE	A, #34h, TRYCAN2	;If A = "4" then connection OK
	JMP	CONNECT
TRYCAN2:
	CJNE	A, #0Dh, TRYCAN1	;if A = CR wait 2 second  and try again
;add some thing here
	MOV	A, #LCD_SETDDADDR+41h	;set address to line2+1
	CALL	WRCMD
	JMP	$+6		;jump CALL RBYTE
TRYCAN3:
	CALL	WRCHAR
	CALL	RBYTE
	CJNE	A, #0Dh, TRYCAN3	;If A = "CR " then delay & retry again
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	JMP	TRYCAN		;request again
CONNECT:
;loop to check > feed back
	CALL	RBYTE
	CJNE	A, #3Eh, $-3	;ELM connected OK
	MOV	A, #LCD_SETVISIBLE+100b	; display on + nocursor + noblink
	CALL	WRCMD
;==============Load setting from EEPROM=====================
LOADEEP:
	MOV	R0, #ECONFIG
	CALL	IPR		;read Back light & beep  status Result in R1
	JB	EEPERR, READERR	;EEPROM error skip loading
	MOV	CONFIG, R1
	MOV	A, CONFIG	;check backlight
	MOV	AUTOBLSTAT, ACC.0	;keep auto back light status
;JB	ACC.0,$+5	;back light on then skip
;SETB	BL		;turn off

	MOV	R0, #EPID1	;Read PID1 from eeprom
	CALL	IPR
	MOV	PID1, R1

	MOV	R0, #EPID2	;Read PID2 from eeprom
	CALL	IPR
	MOV	PID2, R1

	MOV	R0, PID1	;load limit pid from eeprom
	CALL	IPR		;Result in R1
	MOV	LIMITCHK1, R1	;keep in LIMITCHK1
	MOV	R0, PID2	;load limit pid from eeprom
	CALL	IPR		;Result in R1
	MOV	LIMITCHK2, R1	;keep in LIMITCHK2

;etc add here
	JMP	METER		;Skip to METER (no error)
READERR:
	MOV	A, CONFIG
	CLR	ACC.4
	MOV	CONFIG, A	;turn off Warning Light mode
	MOV	A, #LCD_SETDDADDR+40h	;set address to line2
	CALL	WRCMD
	MOV	DPTR, #RDERR	;Show EEprom error message
	CALL	WRSTR
	CALL	SOUND_BEEP
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
;===========================================================	
METER:
	CALL	LINE1		;first line PID display
	CALL	LINE2		;second line PID display
;send AT command
	MOV	A, #0Dh
	CALL	SBYTE		;send CR to receive > and start receive data
;*************** MAIN LOOP **********************************
MAIN:				;Main Loop
;***** check PID mode and send command to ELM and show string to LCD
	MOV	A, AUTOBLSTAT
	JNB	ACC.0, $+12	;Auto BLoff thenskip
	JB	EEPWP, $+7	;if LDR hi then jump
	CLR	BL		;turn on backlight
	SJMP	$+4
	SETB	BL		;turn off backlight
;---------------------------------------------
	JB	BTNBL, $+11	;toggle back light
	CALL	BACKLIGHT
	MOV	A, #0Dh
	CALL	SBYTE		;send CR to receive > and start receive data

	JNB	BTNMENU, SETUP0	;enter setup mode
	JB	RI, RECEIVE	;read back data from ELM
;***** PID mode change button check**********
MAIN3:
	JB	BTNUP, MAIN2	;next mode Line1
	CALL	SOUND_TRIG
	INC	PID1		;add pid1+1
	MOV	A, PID1
	CALL	SKIPPID		;skip unused PID mode
	MOV	PID1, A		;Return skipped PID mode

	MOV	R0, PID1	;load limit pid from eeprom
	CALL	IPR		;Result in R1
	MOV	LIMITCHK1, R1	;keep in LIMITCHK1

	CALL	LINE1
	CALL	DEL100m		;keyboard delay
	CALL	DEL100m		;keyboard delay
	CALL	DEL100m		;keyboard delay
;addition
	MOV	A, #0Dh		;send CR again 
	CALL	SBYTE
	JMP	MAIN
;------------
MAIN2:
	JB	BTNDN, MAIN	;next mode Line2
	CALL	SOUND_TRIG
	INC	PID2		;add pid1+1
	MOV	A, PID2
	CALL	SKIPPID		;skip unused PID mode
	MOV	PID2, A		;Return skipped PID mode

	MOV	R0, PID2	;load limit pid from eeprom
	CALL	IPR		;Result in R1
	MOV	LIMITCHK2, R1	;keep in LIMITCHK2

	CALL	LINE2		;Update LCD 
	CALL	DEL100m		;keyboard delay
	CALL	DEL100m		;keyboard delay
	CALL	DEL100m		;keyboard delay
;adddition
	MOV	A, #0Dh
	CALL	SBYTE
	JMP	MAIN
SETUP0:
	AJMP	SETUP
;=========END MAIN LOOP=================
RECEIVE:
	CALL	RBLOCK
	MOV	A, PIDTURN
	CJNE	A, #01h, PIDTURN2	;if PIDTURN<> 1 then goto PIDTURN2
;LCD LINE1**********************************
;CALL	LINE1		;Display PID mode in LINE1
	CALL	GETB1B2		;Translate ASCII in buffer to Hex Data and keep in B1,B2
	MOV	R2, PID1	;keep PID1 mode in R2 for CALCULATE
	CALL	CALCULATE	;Determine PID mode / calculate /translate to ASCII / keep in BUFFER/RESULTLEN
	CALL	LIGHT1		;check warning lamp
;------Write Result to LCD lin1
	MOV	A, #LCD_SETDDADDR	;set address in LCD to write result in LINE1
	ADD	A, WRADDL1	;add write address
	CALL	WRCMD
	MOV	R1, RESULTLEN	;R1 = Length of result to display
	MOV	R0, #BUFFER	;R0 point to buffer
LENGTH1:
	MOV	A, @R0		;load char in A
	CALL	WRCHAR
	INC	R0
	DJNZ	R1, LENGTH1	;loop til end of length
;check PID2 mode & send AT cmd to ELM
	MOV	PIDTURN, #02h	;set  PIDTURN = 2
;check MODE22 to send 221E1C
	MOV	A, PID2
	CJNE	A, #22h, MODE011	;check if PID is 22h then send 221E1C for TFT
	CALL	SEND221E1C	;send sub routine
	AJMP	MAIN3		;
MODE011:
	MOV	A, #30h
	CALL	SBYTE		;send char0
	MOV	A, #31h
	CALL	SBYTE		;send char1
	MOV	A, PID2		;keep pid2 in temp
	SWAP	A
	ANL	A, #0Fh
	MOV	R1, A
	CALL	HTOA
	CALL	SBYTE		;send higt byte
	MOV	A, PID2		;keep pid2 in temp
	ANL	A, #0Fh
	MOV	R1, A
	CALL	HTOA
	CALL	SBYTE		;send low byte
	MOV	A, #0Dh
	CALL	SBYTE		;send CR
	AJMP	MAIN3
;LINE2********************************************
PIDTURN2:
;CALL	LINE2		;Display PID mode in LINE2
	CALL	GETB1B2		;Translate ASCII in buffer to Hex Data and keep in B1,B2
	MOV	R2, PID2	;keep PID2 mode in R2 for CALCULATE
	CALL	CALCULATE	;Determine PID mode / calculate /translate to ASCII / keep in BUFFER/RESULTLEN
	CALL	LIGHT2		;check warning lamp
;-------Write Result to LCD lin2
	MOV	A, #LCD_SETDDADDR+40h	;set address in LCD to write result in LINE2
	ADD	A, WRADDL2
	CALL	WRCMD
	MOV	R1, RESULTLEN	;R1 = Length of result to display
	MOV	R0, #BUFFER	;R0 point to buffer
LENGTH2:
	MOV	A, @R0		;load char in A
	CALL	WRCHAR
	INC	R0
	DJNZ	R1, LENGTH2
;check PID2 mode & send AT cmd to ELM
	MOV	PIDTURN, #01h	;set PIDTURN = 1
;check MODE22 to send 221E1C
	MOV	A, PID1
	CJNE	A, #22h, MODE012	;check if PID is 22h then send 221E1C for TFT
	CALL	SEND221E1C	;send sub routine
	AJMP	MAIN3		;
MODE012:
	MOV	A, #30h
	CALL	SBYTE		;send char0
	MOV	A, #31h
	CALL	SBYTE		;send char1
	MOV	A, PID1		;keep pid1 in temp
	SWAP	A
	ANL	A, #0Fh
	MOV	R1, A
	CALL	HTOA
	CALL	SBYTE		;send higt byte
	MOV	A, PID1		;keep pid1 in temp
	ANL	A, #0Fh
	MOV	R1, A
	CALL	HTOA
	CALL	SBYTE		;send low byte
	MOV	A, #0Dh
	CALL	SBYTE		;send CR
	AJMP	MAIN3
;********************END of Program*****************************
CONSUMP0:
	AJMP	CONSUMP

SETUP:				; test setup menu
	CLR	LEDUP		;turn off LED
	CLR	LEDDN
	CALL	SOUND_BEEP
	MOV	R4, #0Ah
DEL5m1:
	MOV	R5, #064h
DEL5m3:
	MOV	R7, #03h
DEL5m2:
	MOV	R6, #098h
	JB	BTNMENU, CONSUMP0	;goto fuel consumption mode
	DJNZ	R6, $-3
	DJNZ	R7, DEL5m2
	DJNZ	R5, DEL5m3
	DJNZ	R4, DEL5m1	;end delay loop 

	MOV	A, #LCD_SETDDADDR+00	;Line 1
	CALL	WRCMD
	MOV	DPTR, #MENU1
	CALL	WRSTR
	MOV	A, #LCD_SETDDADDR+40h	;Line2
	CALL	WRCMD
	MOV	DPTR, #MENU2
	CALL	WRSTR
;select mode here
;**************************
SELECT:
	JB	BTNBL, $+6	;toggle backlight
	CALL	BACKLIGHT
	JB	BTNDN, GOSET	;if press down button goto Special function
	AJMP	SPLFUNC
GOSET:
	JB	BTNUP, SELECT
;Enter setup menu
;1) set up Auto Backlight
	CALL	SOUND_TRIG
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETDDADDR+00	;Line 1
	CALL	WRCMD
	MOV	DPTR, #MENU11	;set up back light
	CALL	WRSTR
	MOV	A, #LCD_SETDDADDR+40h	;Line 1
	CALL	WRCMD
	MOV	DPTR, #TOGGLE	;TOGGLE Here
	CALL	WRSTR
BLSTATUS:
	MOV	A, #LCD_SETDDADDR+40h	;Line 1 set address to write ON or OFF
	CALL	WRCMD
	MOV	A, CONFIG	;read current status bit0
	JNB	ACC.0, BLOFF	;if ACC.0 = 0 then goto BLOFF
	MOV	A, #4Fh		;O char
	CALL	WRCHAR
	MOV	A, #4Eh		;N char
	CALL	WRCHAR
	MOV	A, #20h		;space char
	CALL	WRCHAR
	CLR	BL		;turn on
	JMP	SETBL		;jump to set backlight
BLOFF:
	MOV	A, #4Fh		;O char
	CALL	WRCHAR
	MOV	A, #46h		;F char
	CALL	WRCHAR
	MOV	A, #46h		;F char
	CALL	WRCHAR
	SETB	BL		;turn off 
SETBL:
	CALL	DEL500m		;keyboard delay
	JB	BTNBL, $+6	;toggle backlight
	CALL	BACKLIGHT
	JNB	BTNUP, SETSOUND	;press to skip to set sound
	JB	BTNDN, $-9
	CALL	SOUND_TRIG
	MOV	A, CONFIG
	CPL	ACC.0		;toggle value
	MOV	CONFIG, A
	MOV	AUTOBLSTAT, A
	JMP	BLSTATUS	;refresh status
;-------------------------------------------
;2. SET BEEP SOUND
SETSOUND:
	CALL	SOUND_TRIG
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETDDADDR+00	;Line 1
	CALL	WRCMD
	MOV	DPTR, #MENU12	;set BEEP on/OFF
	CALL	WRSTR
	MOV	A, #LCD_SETDDADDR+40h	;Line 1
	CALL	WRCMD
	MOV	DPTR, #TOGGLE	;TOGGLE Here
	CALL	WRSTR
BEEPSTATUS:
	MOV	A, #LCD_SETDDADDR+40h	;Line 1 set address to write ON or OFF
	CALL	WRCMD
	MOV	A, CONFIG	;check beep on/off status bit 1
	JNB	ACC.1, BEEPOFF	;goto beep off
	MOV	A, #4Fh		;O char
	CALL	WRCHAR
	MOV	A, #4Eh		;N char
	CALL	WRCHAR
	MOV	A, #20h		;space char
	CALL	WRCHAR
	JMP	SETBEEP		;jump to set beep
BEEPOFF:
	MOV	A, #4Fh		;O char
	CALL	WRCHAR
	MOV	A, #46h		;F char
	CALL	WRCHAR
	MOV	A, #46h		;F char
	CALL	WRCHAR
SETBEEP:
	CALL	DEL500m		;keyboard delay
	JB	BTNBL, $+6	;toggle backlight
	CALL	BACKLIGHT
	JNB	BTNUP, SETUPPID	;skip to setup pid1&2
	JB	BTNDN, $-9
	CALL	SOUND_TRIG
	MOV	A, CONFIG
	CPL	ACC.1		;toggle value
	MOV	CONFIG, A
	JMP	BEEPSTATUS	;refresh status
;--------------
;3. SET startup PID1
SETUPPID:
	CALL	SOUND_TRIG
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETDDADDR+40h	;Line 2
	CALL	WRCMD
	MOV	DPTR, #MENU13	;PID1
	CALL	WRSTR
SETPID1:
	CALL	LINE1		;write current PID to line1
	CALL	DEL500m		;keyboard delay
	JB	BTNBL, $+6	;toggle backlight
	CALL	BACKLIGHT
	JNB	BTNUP, PID1OK	;
	JB	BTNDN, $-9	;Wait BTN down press
	CALL	SOUND_TRIG
	INC	PID1		;add pid1+1
	MOV	A, PID1
	CALL	SKIPPID		;skip unused PID mode
	MOV	PID1, A		;Return skipped PID mode
	JMP	SETPID1
PID1OK:				;select OK then write to eeprom
	MOV	R0, #EPID1	;save in eeprom
	MOV	R1, PID1
	CALL	IPW
;4. SET statup PID2
	CALL	SOUND_TRIG
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETDDADDR+0	;Line 1
	CALL	WRCMD
	MOV	DPTR, #MENU14	;PID2
	CALL	WRSTR
SETPID2:
	CALL	LINE2		;write current PID to line1
	CALL	DEL500m		;keyboard delay
	JB	BTNBL, $+6	;toggle backlight
	CALL	BACKLIGHT
	JNB	BTNUP, PID2OK
	JB	BTNDN, $-9	;Wait BTN down press
	CALL	SOUND_TRIG
	INC	PID2		;add pid2+1
	MOV	A, PID2
	CALL	SKIPPID		;skip unused PID mode
	MOV	PID2, A		;Return skipped PID mode
	JMP	SETPID2
PID2OK:				;select OK then write to eeprom
	MOV	R0, #EPID2	;save eeprom
	MOV	R1, PID2
	CALL	IPW
;5 Set Lightup Value for Each PID
	CALL	SOUND_TRIG
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETDDADDR+0	;Line 1
	CALL	WRCMD
	MOV	DPTR, #MENU15	;Warning Vaule
	CALL	WRSTR
	MOV	A, #LCD_SETDDADDR+40h	;Line 1
	CALL	WRCMD
	MOV	DPTR, #TOGGLE	;TOGGLE Here
	CALL	WRSTR
PIDSTATUS:
	MOV	A, #LCD_SETDDADDR+40h	;Line 1 set address to write ON or OFF
	CALL	WRCMD
	MOV	A, CONFIG	;check beep on/off status bit 1
	JNB	ACC.3, PIDOFF	;goto PID off
	MOV	A, #4Fh		;O char
	CALL	WRCHAR
	MOV	A, #4Eh		;N char
	CALL	WRCHAR
	MOV	A, #20h		;space char
	CALL	WRCHAR
	JMP	SETPID		;jump to set PID
PIDOFF:
	MOV	A, #4Fh		;O char
	CALL	WRCHAR
	MOV	A, #46h		;F char
	CALL	WRCHAR
	MOV	A, #46h		;F char
	CALL	WRCHAR
SETPID:
	CALL	DEL500m		;keyboard delay
	JB	BTNBL, $+6	;toggle backlight
	CALL	BACKLIGHT
	JNB	BTNUP, AUTOSLEEP	;skip to set autosleep
	JB	BTNDN, $-9
	CALL	SOUND_TRIG
	MOV	A, CONFIG
	CPL	ACC.3		;toggle value
	MOV	CONFIG, A
	JMP	PIDSTATUS	;refresh status
;--------------
;6. Set Auto Sleep Mode
AUTOSLEEP:
	CALL	SOUND_TRIG
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETDDADDR+0	;Line 1
	CALL	WRCMD
	MOV	DPTR, #MENU16	;Warning Vaule
	CALL	WRSTR
	MOV	A, #LCD_SETDDADDR+40h	;Line 1
	CALL	WRCMD
	MOV	DPTR, #TOGGLE	;TOGGLE Here
	CALL	WRSTR
SLEEPSTATUS:
	MOV	A, #LCD_SETDDADDR+40h	;Line 1 set address to write ON or OFF
	CALL	WRCMD
	MOV	A, CONFIG	;check beep on/off status bit 1
	JNB	ACC.4, SLEEPOFF	;goto PID off
	MOV	A, #4Fh		;O char
	CALL	WRCHAR
	MOV	A, #4Eh		;N char
	CALL	WRCHAR
	MOV	A, #20h		;space char
	CALL	WRCHAR
	JMP	SETSLEEP	;jump to set sleep
SLEEPOFF:
	MOV	A, #4Fh		;O char
	CALL	WRCHAR
	MOV	A, #46h		;F char
	CALL	WRCHAR
	MOV	A, #46h		;F char
	CALL	WRCHAR
SETSLEEP:
	CALL	DEL500m		;keyboard delay
	JB	BTNBL, $+6	;toggle backlight
	CALL	BACKLIGHT
	JNB	BTNUP, VERSION	;skip to firmware Version
	JB	BTNDN, $-9
	CALL	SOUND_TRIG
	MOV	A, CONFIG
	CPL	ACC.4		;toggle value
	MOV	CONFIG, A
	JMP	SLEEPSTATUS	;refresh status
;--------------
;7  Firmware Version
VERSION:
	CALL	SOUND_TRIG
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETDDADDR+0	;Line 1
	CALL	WRCMD
	MOV	DPTR, #MENU17	;Upgrade Fimrware
	CALL	WRSTR
	MOV	A, #LCD_SETDDADDR+40h	;Line 2
	CALL	WRCMD
	MOV	DPTR, #RELEASE	;Release Date
	CALL	WRSTR
	CALL	DEL500m		;keyboard delay
	JB	BTNBL, $+6	;toggle backlight
	CALL	BACKLIGHT
	JB	BTNUP, $-6	;Repeat til press to exit
	CALL	SOUND_TRIG
	CALL	DEL500m		;keyboard delay
;write setting in EEPROM
	MOV	R1, CONFIG	;Save CONFIG setting before getting out
	MOV	R0, #ECONFIG	;set eeprom address
	CALL	IPW		;Write setting to eeprom
	JB	EEPERR, WRITEERR	;no error exit setup
	AJMP	METER		;goback to main loop
WRITEERR:			;eepromp writing error
	MOV	A, #LCD_SETDDADDR+40h	;set address to line2
	CALL	WRCMD
	MOV	DPTR, #WRERR	;Show EEprom error message
	CALL	WRSTR
	CALL	SOUND_BEEP
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	CALL	DEL500m
	AJMP	METER		;goback to main loop
;********************************************************
;Special Function Menu
SPLFUNC:
;VIN
	CALL	SOUND_TRIG
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETDDADDR+00	;Line 1
	CALL	WRCMD
	MOV	DPTR, #VEHINFO	;show vehicle information no.
	CALL	WRSTR
;additional code here ???? 
	CALL	DEL500m		;keyboard delay
	JB	BTNBL, $+6	;toggle backlight
	CALL	BACKLIGHT
	JB	BTNUP, $-6
;--------------------------------
;NO of DTC
	CALL	SOUND_TRIG
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETDDADDR+00	;Line 1
	CALL	WRCMD
	MOV	DPTR, #DTC	;no. of DTC
	CALL	WRSTR
	CLR	RI		;clear RI
	MOV	DPTR, #DTCPID
	CALL	SBLOCK		;send 0101
	CALL	RBLOCK		;receive result from ELM
	CALL	GETB1B2		;get Byte1 Byte2
	MOV	A, B1
	JZ	SHOWDTC		;IF B1=0 then goto SHOWDTC else next
	SUBB	A, #80h		;A - 80h = DTC no.
	MOV	B1, A		;keep no. DTC in B1
SHOWDTC:
	MOV	DPTR, #0000h
	MOV	DPL, B1
	CALL	HTOD		;Result in R3
	MOV	A, #LCD_SETDDADDR+17	;set cursor position
	CALL	WRCMD
	MOV	A, R3
	SWAP	A		;get High nibble
	ANL	A, #0Fh
	ADD	A, #30h
	CALL	WRCHAR		;write 1st digit
	MOV	A, R3
	ANL	A, #0Fh
	ADD	A, #30h
	CALL	WRCHAR		;write 2nd digit
	MOV	A, #LCD_SETDDADDR+40h	;set to Line2
	CALL	WRCMD
;check DTC no. = 0 or not
	MOV	A, B1		;Read NO OF DTC
	JNZ	MILISON		;if MIL off jump MILISON
	MOV	DPTR, #MILOFF
	CALL	WRSTR
	CALL	DEL500m		;check keyboard delay
	JB	BTNBL, $+6	;toggle backlight
	CALL	BACKLIGHT
	JB	BTNUP, $-6
	CALL	SOUND_TRIG
;----------------------
	CALL	DEL500m		;keyboard delay
	AJMP	METER		;back to PID mode
;----------------------
MILISON:			;MIL is on next show DTCs
	SETB	LEDUP		;turn on LED UP
	MOV	DPTR, #MILON	;show message "Press to read DTC ->"
	CALL	WRSTR
	CALL	SOUND_BEEP	;BEEP warning
	CALL	DEL500m		;check keyboard delay
	JB	BTNBL, $+6	;toggle backlight
	CALL	BACKLIGHT
	JB	BTNDN, $-6
	CALL	SOUND_TRIG
	MOV	A, #LCD_SETDDADDR+40h	;set to Line2
	CALL	WRCMD
	MOV	DPTR, #DISPDTC
	CALL	WRSTR
;Read Diagnosis troube code and show here
	MOV	DPTR, #DTCREAD	;send 03 to read all DTC
	CALL	SBLOCK
	CALL	RBLOCK		;Receive DTC in buffer
	MOV	@R0, A		;Keep ">" in buffer
;------------------- DTC interpreter start here ------------------------
;DTC Header checking 43 first
	MOV	R0, #19h	;R0 point to buffer
CHECK4:
	INC	R0
	CJNE	@R0, #34h, CHECK4	;check 43 (check only 4)
	INC	R0
	CJNE	@R0, #33h, CHECK4
	MOV	A, R0		;found 43
	ADD	A, #04h		;skip no of DTC byte
	MOV	R0, A		;R0 point to the first byte of DTC
	MOV	TEMP3, #00h	;Counter DTC

DTC1READ:
	MOV	A, #LCD_SETDDADDR+40h	;set to Line2
	CALL	WRCMD

DTCINTP:
	INC	R0
	CJNE	@R0, #3Eh, $+6	;check ">" if not interpret code now
	JMP	CLEARMIL	;exit to CLEAR MIL
	INC	R0
	CJNE	@R0, #3Eh, $+6	;check ">" if not interpret code now
	JMP	CLEARMIL	;exit to CLEAR MIL
	DEC	R0
	CJNE	@R0, #20h, $+5	;check "SP"
	JMP	DTCINTP
	CJNE	@R0, #0Dh, $+5	;check "CR" 
	JMP	DTCINTP
	CJNE	@R0, #3Ah, $+5	;check ":" 
	JMP	DTCINTP
	INC	R0		;skip to check next byte
	CJNE	@R0, #3Ah, $+5	;check ":" next byte
	JMP	DTCINTP
	DEC	R0		;IF not  1: back last byte
;check #00 value to exit from read DTC
	CJNE	@R0, #30h, SKIPNULL1
	INC	R0
	CJNE	@R0, #30h, SKIPNULL2
	JMP	CLEARMIL	;IF read data is 00 then skip to clear MIL
SKIPNULL2:
	DEC	R0
SKIPNULL1:
;1 DTC code read checking for CR
;display to LCD  write number first
	MOV	TEMP1, R0	;keep R0
	MOV	DPTR, #0000h
	INC	TEMP3
	MOV	DPL, TEMP3
	CALL	HTOD		;convert counter to dec output R3
	MOV	A, R3
	ANL	A, #11110000b
	SWAP	A
	CALL	HTOA
	CALL	WRCHAR		;write 1st digit
	MOV	A, R3
	ANL	A, #00001111b
	CALL	HTOA
	CALL	WRCHAR
	MOV	A, #2Dh		; "-" sign
	CALL	WRCHAR
	MOV	R0, TEMP1	;return R0
;interpret now
	CALL	INTPDTC		;inteprte troube code ,save result PX in buffer
	MOV	A, R1		;show DTC 1st digit
	CALL	WRCHAR
	MOV	A, R2		;show DTC 2nd digit
	CALL	WRCHAR
;PX read now read remaining 3 byte code
	INC	R0		;point to next byte
	MOV	A, @R0
	CALL	WRCHAR		;show DTC 3rd digit
	INC	R0		;skip space
	INC	R0
	MOV	A, @R0
	CALL	WRCHAR		;show DTC 4th digit
	INC	R0
	MOV	A, @R0
	CALL	WRCHAR		;show DTC 5th digit
;read next line here
	CALL	DEL500m		;check keyboard delay
	JB	BTNBL, $+6	;toggle backlight
	CALL	BACKLIGHT
	JB	BTNDN, $-6
	CALL	SOUND_TRIG
	JMP	DTC1READ	;Jump back to read next couple byte
;change end code from CR to 00
CLEARMIL:
;No more DTC Clear MIL status or not
	MOV	A, #LCD_SETDDADDR+40h	;Line 2
	CALL	WRCMD
	MOV	DPTR, #SETMIL	;Clear MIL  |  [NO ]->
	CALL	WRSTR
	MOV	TEMP3, #00	;TEMP3= 00  -> not clear ,TEMP3=1 -> clear MIL
MILSTATUS:
	MOV	A, #LCD_SETDDADDR+4Fh	;Line 2 set address to write YES or NO
	CALL	WRCMD
	MOV	A, TEMP3
	JNB	ACC.0, NOTCLR	;no MIL clear
	MOV	A, #59h		;Y char
	CALL	WRCHAR
	MOV	A, #45h		;E char
	CALL	WRCHAR
	MOV	A, #53h		;S char
	CALL	WRCHAR
	JMP	SETMILOFF	;jump to set MIL off
NOTCLR:
	MOV	A, #4Eh		;N char
	CALL	WRCHAR
	MOV	A, #4Fh		;O char
	CALL	WRCHAR
	MOV	A, #20h		;Space
	CALL	WRCHAR
SETMILOFF:
	CALL	DEL500m		;keyboard delay
	JB	BTNBL, $+6	;toggle backlight
	CALL	BACKLIGHT
	JNB	BTNUP, SPLEXIT	;skip to exit special function
	JB	BTNDN, $-9
	CALL	SOUND_TRIG
	MOV	A, TEMP3
	CPL	ACC.0		;toggle value
	MOV	TEMP3, A
	JMP	MILSTATUS	;refresh status
SPLEXIT:
	MOV	A, TEMP3
	JNB	ACC.0, $+9	;NO then skip CLR MIL 
;send CLRMIL  0400 Message Here
	MOV	DPTR, #CLRMIL
	CALL	SBLOCK
	CALL	DEL500m		;keyboard delay
	AJMP	METER		;back to PID mode
;----------------------
;***********END CONFIG******************
CONSUMP:
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETDDADDR+00	;Line 1
	CALL	WRCMD
	MOV	DPTR, #SPDMAF
	CALL	WRSTR
	MOV	A, #LCD_SETDDADDR+40h	;Line 2
	CALL	WRCMD
	MOV	A, CONFIG	;check default FC mode
	JB	ACC.2, AVRMODE	;goto average mode
;Instant mode
	MOV	DPTR, #INSTFC
	CALL	WRSTR
	JMP	CONSUMP2
AVRMODE:
	MOV	DPTR, #AVRFC
	CALL	WRSTR

CONSUMP2:			;calculate loop
;---Get Vehicle Speed
	MOV	DPTR, #SPDPID
	CALL	SBLOCK		;send 010D to ELM
	CALL	RBLOCK
	CALL	GETB1B2
	MOV	TEMP1, B1	;keep speed in temp1
	CALL	FORMULA3	;calculate speed result in BUFFER
	MOV	A, #LCD_SETDDADDR+0	;set cursot line1 
	CALL	WRCMD
	MOV	R1, RESULTLEN
	MOV	R0, #BUFFER	;point to buffer
VEHSPD:
	MOV	A, @R0		;load char in A
	CALL	WRCHAR
	INC	R0
	DJNZ	R1, VEHSPD	;loop til end of length
;---Get Manifold Air Flow
	MOV	DPTR, #MAFPID
	CALL	SBLOCK		;send 010D to ELM
	CALL	RBLOCK
	CALL	GETB1B2
	MOV	TEMP2, B1	;keep airflow in temp2
	MOV	TEMP3, B2	;keep airflow in temp3
	CALL	AIRFLOW		;calculate airflow result in buffer
	MOV	A, #LCD_SETDDADDR+11	;set cursor line1 
	CALL	WRCMD
	MOV	R1, RESULTLEN
	MOV	R0, #BUFFER	;point to buffer
MAF:
	MOV	A, @R0		;load char in A
	CALL	WRCHAR
	INC	R0
	DJNZ	R1, MAF		;loop til end of length
;calculate fuel consumption & display on Line 2
;FC = (speed x 1Dhx0Ah)/ (Airflow /0Ah)  [100%]
	MOV	R1, TEMP2	;Airflow /0Ah
	MOV	R0, TEMP3
	MOV	R3, #00h
	MOV	R2, #0Ah
	CALL	UDIV16		;result in R1,R0
	MOV	TEMP2, R1
	MOV	TEMP3, R0

	MOV	R1, #00h
	MOV	R0, TEMP1	;Speed x 1Dhx0Ah = Speedx 122h
	MOV	R3, #01h
;FC = (speed x 1Ch,x0Ah)/(Airflow/0Ah)   [ 5% compensation]
	MOV	R2, #13h
;MOV	R2,#22h		;100%
	CALL	UMUL16		;result in R3,R2,R1,R0 (use only R1 R0)
	MOV	R3, TEMP2	;prepare divider
	MOV	R2, TEMP3

	CALL	UDIV16		;result in R1,R0
;end FC calculate
	MOV	DPH, R1		;keep result in DPTR
	MOV	DPL, R0
;check F/C mode
	MOV	A, CONFIG
	JNB	ACC.2, INSTMODE	;skip to INSTANT mode

;keep logging data in iram 80h-FFh
	INC	FCPTR
	MOV	R0, FCPTR	;#80h
	MOV	@R0, DPH
	INC	R0		;#81h
	MOV	@R0, DPL
	MOV	FCPTR, R0	;#81h

	MOV	A, FCPTR	;check end of data at 0FFh or not
	CJNE	A, #0FFh, FCKEY	;not end of data jump to FCKEY
;Start average here
	MOV	R0, #080h	;R0 point to 81h
	MOV	R1, #081h	;R1 point to 83h
	MOV	DPH, @R0	;first data HI byte in DPH
	MOV	DPL, @R1	;first data LOW byte in DPL
	MOV	R0, #082h	;R0 point to 82h
	MOV	A, @R0
	MOV	R3, A		;2 nd data High Nibble  in R3
	INC	R0
	MOV	A, @R0
	MOV	R2, A		;2nd data Low Nibble  in R2
	MOV	R1, DPH		;1st data in R1,R0
	MOV	R0, DPL		;;1st data in R1,R0
	MOV	TEMP1, #083h	;data index
AVERAGE:			;average every 64 data logging then divide by 64 at final
	CALL	ADD16		;16bit add		result in R1,R0	
	MOV	DPH, R1		;keep sum result in DPTR
	MOV	DPL, R0
	INC	TEMP1		;84h
	MOV	R0, TEMP1
	MOV	A, @R0		;Load Next data digit1 84h
	MOV	R3, A
	INC	R0
	MOV	A, @R0		;Load Next data digit2 85h
	MOV	R2, A
	MOV	TEMP1, R0	;TEMP1 = 85h
	MOV	R1, DPH		;1st data in R1,R0 load result back
	MOV	R0, DPL		;;1st data in R1,R0
	MOV	A, TEMP1
	CJNE	A, #0FFh, AVERAGE	;not end of data average again
	MOV	R3, #00h
	MOV	R2, #64
	CALL	UDIV16		;Divide by 64 Result in R1,R0
	MOV	DPH, R1
	MOV	DPL, R0		;Prepare data for HTOD
	MOV	FCPTR, #7Fh	;reset pointer
INSTMODE:
	CALL	HTOD		;convert result to DEC
	MOV	A, #LCD_SETDDADDR+76	;set cursot line1 
	CALL	WRCMD
	MOV	A, R2
	ANL	A, #0Fh
	JZ	FCZERO
	ADD	A, #30h		;change to ascii
	JMP	FCNONZERO
FCZERO:
	MOV	A, #17h		;space
FCNONZERO:
	CALL	WRCHAR		;write 1 st digit
	MOV	A, R3
	SWAP	A
	ANL	A, #0Fh
	ADD	A, #30h
	CALL	WRCHAR		;write 2nd digit
	MOV	A, #2Eh
	CALL	WRCHAR		;write full stop
	MOV	A, R3
	ANL	A, #0Fh
	ADD	A, #30h
	CALL	WRCHAR		;write 3nd digit
;end calculation fuel consumption and check button press
FCKEY:
	JB	BTNBL, $+6	;toggle back light
	CALL	BACKLIGHT
	JB	BTNUP, FCMODE
	CALL	SOUND_TRIG
	MOV	A, CONFIG	;Instant mode
	CLR	ACC.2
	MOV	CONFIG, A
	LJMP	CONSUMP		;restart FC
FCMODE:
	JB	BTNDN, FCEXIT
	CALL	SOUND_TRIG
	MOV	A, CONFIG
	SETB	ACC.2		;Average mode;
	MOV	CONFIG, A
	LJMP	CONSUMP		;Restart FC
FCEXIT:
	JB	BTNMENU, CONSUMP3	;jump back to calculte consump
	CALL	SOUND_TRIG
	MOV	R0, #ECONFIG	;set eeprom address
	MOV	R1, CONFIG	;save last mode in EEPROM
	CALL	IPW		;Write setting to eeprom
	CALL	DEL500m
	CALL	DEL500m		;key delay
	LJMP	METER		;Exit
CONSUMP3:
	LJMP	CONSUMP2
;============SUB ROUTINE=======================
;SKIP PID  IN A(PID mode) OUT  A and PID
SKIPPID:
	CJNE	A, #08h, $+6
	MOV	A, #0Ah
	RET
	CJNE	A, #12h, $+6
	MOV	A, #14h
	RET
	CJNE	A, #16h, $+6
	MOV	A, #22h
	RET
	CJNE	A, #24h, $+6
	MOV	A, #2Ch
	RET
	CJNE	A, #30h, $+6
	MOV	A, #33h
	RET
	CJNE	A, #34h, $+6
	MOV	A, #3Ch
	RET
	CJNE	A, #3Eh, $+6
	MOV	A, #42h
	RET
	CJNE	A, #47h, $+5
	MOV	A, #04h
	RET
;*********************************
;IN   B1,B2 ,R2
;OUT   BUFFER,RESULTLEN
CALCULATE:			;Determine PID mode / calculate /translate to ASCII / keep in BUFFER/RESULTLEN

	CJNE	R2, #04h, $+7	;CAL Engine Load
	CALL	FORMULA1
	RET
	CJNE	R2, #05h, $+7	;Coolant Temp
	CALL	FORMULA2
	RET
	CJNE	R2, #06h, $+7	;Short Term Fuel TRim B1
	CALL	FUELTRIM
	RET
	CJNE	R2, #07h, $+7	;Long Term Fuel Trim B1
	CALL	FUELTRIM
	RET
	CJNE	R2, #0Ah, $+7	;Fuel Pressure
	CALL	FORMULA3
	RET
	CJNE	R2, #0Bh, $+7	;MAN air Press
	CALL	FORMULA3
	RET
	CJNE	R2, #0Ch, $+7	;ENG Speed
	CALL	ENGSPEED
	RET
	CJNE	R2, #0Dh, $+7	;VEH Speed
	CALL	FORMULA3
	RET
	CJNE	R2, #0Eh, $+7	;IGN ADV Timing
	CALL	IGNTIME
	RET
	CJNE	R2, #0Fh, $+7	;Intake Air Temp
	CALL	FORMULA2
	RET
	CJNE	R2, #10h, $+7	;Air Flow
	CALL	AIRFLOW
	RET
	CJNE	R2, #11h, $+7	;Throttle Pos
	CALL	FORMULA1
	RET
	CJNE	R2, #14h, $+7	;HO2S 1 voltage
	CALL	HO2SVOLT
	RET
	CJNE	R2, #15h, $+7	;HO2S 2 voltage
	CALL	HO2SVOLT
	RET
	CJNE	R2, #22h, $+7	;Transmission Fluid Temp
	CALL	CALTFT
	RET
	CJNE	R2, #23h, $+7	;Fuel Rail Pressure
	CALL	AIRFLOW		;Same Formula as Air Flow
	RET
	CJNE	R2, #2Ch, $+7	;Command EGR
	CALL	FORMULA1
	RET
	CJNE	R2, #2Dh, $+7	;EGR error
	CALL	FORMULA1
	RET
	CJNE	R2, #2Eh, $+7	;Command Evap Purge
	CALL	FORMULA1
	RET
	CJNE	R2, #2Fh, $+7	;Fuel Level
	CALL	FORMULA1
	RET
	CJNE	R2, #33h, $+7	;Baro Press
	CALL	FORMULA3
	RET
	CJNE	R2, #3Ch, $+7	;CAT 1 Temp
	CALL	CATTEMP
	RET
	CJNE	R2, #3Dh, $+7	;CAT 2 Temp
	CALL	CATTEMP
	RET
	CJNE	R2, #42h, $+7	;ECU Volt
	CALL	ECUVOLT
	RET
	CJNE	R2, #43h, $+7	;ABS ENgine load
	CALL	FORMULA1
	RET
	CJNE	R2, #44h, $+7	;CMD EQV RAtio
	CALL	CMDEQV
	RET
	CJNE	R2, #45h, $+7	;REL Throt Pos
	CALL	FORMULA1
	RET
	CJNE	R2, #46h, $+6	;AMB Air Temp
	CALL	FORMULA2
	RET
	CJNE	R2, #5Ch, $+6	;AMB Air Temp
	CALL	FORMULA2
	RET
;***********************************
;--SUB Formula Caculation---------------------------------------
;IN   B1,B2
;OUT BUFFER, RESULTLEN
FORMULA1:			;Percentage calculate B1/255 x 100
	MOV	A, B1
	MOV	B, #100
	MUL	AB		;result in BA
	MOV	DPTR, #0000h	;DPTR=0
	MOV	DPL, A		;DPL=A
	CALL	HTOD		;Result fraction A keep in R2,R3  take only R2 low nibble
	MOV	A, R2		;keep carry in A
	MOV	DPTR, #0000h
	MOV	DPL, B		;take byte1 
	ADD	A, B		;add byte1 with carry 
	MOV	DPTR, #000h	;final result for HTOD
	MOV	DPL, A
	CALL	HTOD		;Result in R2,R2

	MOV	A, R2
	ANL	A, #0Fh
	MOV	R4, A		;keep
	JZ	$+9		;IF A = 0 then skip to BUFFER = #17h
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER, A	;digit1
	JMP	$+6
	MOV	BUFFER, #17h	;Result is 0 then put SPACE
	MOV	A, R3
	SWAP	A
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+1, A	;digit2
	MOV	A, R3
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+2, A	;digit1
	MOV	RESULTLEN, #03
	RET
;------------------
FORMULA2:			;Temperature B1-40
	MOV	DPTR, #0000h
	MOV	A, B1
	CLR	C
	SUBB	A, #40
	MOV	DPL, A
	CALL	HTOD
	MOV	A, R2
	ANL	A, #0Fh
	JZ	$+9		;IF A = 0 then skip to BUFFER = #17h
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER, A	;digit1
	JMP	$+6
	MOV	BUFFER, #17h	;Result is 0 then put SPACE
	MOV	A, R3
	SWAP	A
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+1, A	;digit2
	MOV	A, R3
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+2, A	;digit1
	MOV	RESULTLEN, #03
	RET
;------------------
FORMULA3:			;direct byte
	MOV	DPTR, #0000h
	MOV	DPL, B1
	CALL	HTOD		;convert hex to Decimal (R1,R2,R3)
	MOV	A, R2
	ANL	A, #0Fh
	JZ	$+9		;IF A = 0 then skip to BUFFER = #17
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER, A	;digit1
	JMP	$+6
	MOV	BUFFER, #17h	;Result is 0 then put SPACE
	MOV	A, R3
	SWAP	A
	ANL	A, #0Fh
	MOV	R7, BUFFER	;check space or not
	CJNE	R7, #17h, $+5
	JZ	$+9		;If 1digit =0 and 2 digit = 0 then jump
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+1, A	;digit2
	JMP	$+6
	MOV	BUFFER+1, #17h	;Result is 0 then put SPACE
	MOV	A, R3
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+2, A	;digit1
	MOV	RESULTLEN, #03
	RET
;--------------------
FUELTRIM:			;( B1x64h)/80h - 64h
	MOV	A, B1
	MOV	B, #64h
	MUL	AB		;Result in B,A
	MOV	R1, B
	MOV	R0, A
	MOV	R3, #00
	MOV	R2, #80h
	CALL	UDIV16		;Result in R1,R0
	CLR	C		;clear carry flag
	MOV	A, R0
	SUBB	A, #64h		;Result in ACC
;Sign checking
	JC	$+9		; OV set then negative sign
	MOV	BUFFER, #2Bh	;+sign
	JMP	POSFT
	MOV	BUFFER, #2Dh	;-Sign
	MOV	R4, A
	MOV	A, #64h
	SUBB	A, R4		;64h - A
POSFT:
	MOV	DPTR, #0000h
	MOV	DPL, A
	CALL	HTOD		;convert hex to Decimal (R1,R2,R3)
	MOV	A, R3
	SWAP	A
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+1, A	;digit2
	MOV	A, R3
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+2, A	;digit1
	MOV	RESULTLEN, #03
	RET
;--------------------
ENGSPEED:			;[(B1x256) + B2] / 4
	MOV	A, B1
	MOV	B, #04h
	DIV	AB		;B1/4  fraction in B
	MOV	DPH, A		;keep A in DPH
	MOV	A, #40h
	MUL	AB		;A = B x #40h   Result in BA
	MOV	R4, A		;keep result in R4
	MOV	A, B2
	MOV	B, #04h
	DIV	AB
	ADD	A, R4		;B2/4 + R4
	MOV	DPL, A		;keep A in DPL
	CALL	HTOD		;Result  in R2,R3 then convert to ASCII
	MOV	A, R2		;digit1
	SWAP	A
	ANL	A, #0Fh
	JZ	$+9		;IF A = 0 then skip to BUFFER = #17h
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER, A	;digit1
	JMP	$+6
	MOV	BUFFER, #17h	;Result is 0 then put SPACE
	MOV	A, R2		;digit2
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+1, A	;digit2
	MOV	A, R3		;digit3
	SWAP	A
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+2, A	;digit3
	MOV	A, R3		;digit4
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+3, A	;digit4
	MOV	RESULTLEN, #04
	RET
;-------------------
IGNTIME:			;(B1 / 2) -64h
	MOV	A, B1
	MOV	B, #02h
	DIV	AB
	CLR	C
	SUBB	A, #64
;Sign checking
	JC	$+9		; OV set then negative sign
	MOV	BUFFER, #2Bh	;+sign
	JMP	POS
	MOV	BUFFER, #2Dh	;-Sign
	MOV	R4, A
	MOV	A, #0FFh
	SUBB	A, R4
	ADD	A, #02h		;correction

POS:
	MOV	DPTR, #0000h
	MOV	DPL, A
	MOV	R4, A		;keep A in R4
	CALL	HTOD		;convert hex to Decimal (R1,R2,R3)
	MOV	A, R3
	SWAP	A
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+1, A	;digit2
	MOV	A, R3
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+2, A	;digit1
	MOV	RESULTLEN, #03
	RET
;-------------------------
AIRFLOW:			;[(B1x256)+B2]/100
	MOV	DPH, B1
	MOV	DPL, B2		;keep A in DPL
	CALL	HTOD		;Result  in R2,R3 then convert to ASCII
	MOV	A, R1		;digit1
	JZ	$+9		;IF A = 0 then skip to BUFFER = #17h
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER, A	;digit1
	JMP	$+6
	MOV	BUFFER, #17h	;Result is 0 then put SPACE

	MOV	A, R2		;digit2
	SWAP	A
	ANL	A, #0Fh
	MOV	R7, BUFFER	;check 1digit is zero or not
	CJNE	R7, #17h, $+5	;if BUFFER <> space then jump to ADD  A,#20h
	JZ	$+9
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+1, A
	JMP	$+6
	MOV	BUFFER+1, #17h	;Result is 0 then put SPACE
	MOV	A, R2		;digit4
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+2, A	;digit2
	MOV	A, R3		;digit5
	SWAP	A
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+4, A	;digit3
	MOV	BUFFER+3, #2Eh	;full stop
	MOV	RESULTLEN, #05
	RET
;-------------------------
CATTEMP:			;[(B1x256)+B2]/10 - 40
	MOV	DPH, B1
	MOV	DPL, B2
	CALL	HTOD		;Result  in R2,R3 then convert to ASCII
;change R2 to Hex, then -4 and change back to dec
	MOV	A, R2
	MOV	B, #10h
	DIV	AB
	MOV	R2, B
	MOV	B, #0Ah
	MUL	AB
	ADD	A, R2		; now return hex
	SUBB	A, #04h		; as equation

	MOV	B, #0Ah
	DIV	AB
	MOV	R2, B
	MOV	B, #10h
	MUL	AB
	ADD	A, R2		; now return DEC

	SWAP	A		; digit1
	ANL	A, #0Fh
	JZ	$+9		;IF A = 0 then skip to BUFFER = #17h
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER, A	;digit1
	JMP	$+6
	MOV	BUFFER, #17h	;Result is 0 then put SPACE
	MOV	A, R2		;digit2
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+1, A	;digit2
	MOV	A, R3		;digit3
	SWAP	A
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+2, A	;digit3
	MOV	A, R3		;digit4
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+4, A	;digit4
	MOV	BUFFER+3, #2Eh	;full stop
	MOV	RESULTLEN, #05
	RET
;-------------------------
ECUVOLT:			;[(B1x256)+B2]/1000
	MOV	DPH, B1
	MOV	DPL, B2		;keep A in DPL
	CALL	HTOD		;Result  in R2,R3 then convert to ASCII
	MOV	A, R1		;digit1
	JZ	$+9		;IF A = 0 then skip to BUFFER = #17h
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER, A	;digit1
	JMP	$+6
	MOV	BUFFER, #17h	;Result is 0 then put SPACE
	MOV	A, R2		;digit2
	SWAP	A
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+1, A	;digit2
	MOV	A, R2		;digit4
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+3, A	;digit2
	MOV	A, R3		;digit5
	SWAP	A
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+4, A	;digit3
	MOV	BUFFER+2, #2Eh	;full stop
	MOV	RESULTLEN, #05
	RET
CMDEQV:				;calculate commanded equivalent ratio (B1x256 + B2) / 32768
	MOV	A, B1
	MOV	B, #64h
	MUL	AB		;B1x100  Result in BA
	MOV	R1, B
	MOV	R0, A
	MOV	R3, #00h
	MOV	R2, #80h
	CALL	UDIV16		; {B1x100 /128} Result in R1,R0
	MOV	DPH, R1
	MOV	DPL, R0
	CALL	HTOD		;convert to decimal resultin R1,R2,R3
	MOV	A, R2
	ADD	A, #30h
	MOV	BUFFER, A	;1st digit
	MOV	BUFFER+1, #2Eh	;full stop
	MOV	A, R3
	SWAP	A
	ANL	A, #0Fh
	ADD	A, #30h
	MOV	BUFFER+2, A	;2nd digit
	MOV	A, R3
	ANL	A, #0Fh
	ADD	A, #30h
	MOV	BUFFER+3, A	;3rd digit
	MOV	RESULTLEN, #04
	RET
HO2SVOLT:			;Volt = B1/200
	MOV	A, B1
	MOV	B, #100
	MUL	AB		;result in BA
	MOV	R1, B
	MOV	R0, A
	MOV	R3, #00h
	MOV	R2, #0C8h
	CALL	UDIV16		; {B1B2 / #0C8h} Result in R1,R0
	MOV	DPH, R1
	MOV	DPL, R0
	CALL	HTOD		;convert to decimal resultin R1,R2,R3
	MOV	A, R2
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER, A	;digit1
	MOV	BUFFER+1, #2Eh	;full stop
	MOV	A, R3
	SWAP	A
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+2, A	;digit2
	MOV	A, R3
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+3, A	;digit3
	MOV	RESULTLEN, #04
	RET
;——————————————————
CALTFT:				;[((B1x256)+B2]/8 - 32)/1.8]   deg C
	;convert to simple equation  ((B1x256)+B2 - 256)x10 /144
	MOV	A, B1
	SUBB	A, #01h		; (B1B2 - 100h)
	MOV	R1, A
	MOV	R0, B2
	MOV	R3, #0h
;MOV	R2,#0Ah ;10
	MOV	R2, #64h	;100
	CALL	UMUL16		;result in R3,R2,R1,R0	32 bit result keep R3 for calculate later
	MOV	B1, R2		;keep R2
	MOV	R3, #00h
	MOV	R2, #90h	;144
	CALL	UDIV16		;result in R1,R0
	MOV	TEMP1, R1
	MOV	TEMP2, R0

	MOV	A, B1
	SWAP	A
	MOV	R1, A
	MOV	R0, #00h
	MOV	R3, #00h
	MOV	R2, #09h
	CALL	UDIV16		;result in R1,R0
	MOV	R3, TEMP1
	MOV	R2, TEMP2
	CALL	ADD16		;R1R0+R3R2  result in R1,R0

	MOV	DPH, R1
	MOV	DPL, R0
	CALL	HTOD		;Result  in R2,R3 then convert to ASCII

	MOV	A, R2
	SWAP	A		; digit1
	ANL	A, #0Fh
	JZ	$+9		;IF A = 0 then skip to BUFFER = #17h
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER, A	;digit1
	JMP	$+6
	MOV	BUFFER, #17h	;Result is 0 then put SPACE
	MOV	A, R2		;digit2
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+1, A	;digit2
	MOV	A, R3		;digit3
	SWAP	A
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+2, A	;digit3
	MOV	A, R3		;digit4
	ANL	A, #0Fh
	ADD	A, #30h		;convert dec to ASCII
	MOV	BUFFER+4, A	;digit4
	MOV	BUFFER+3, #2Eh	;full stop
	MOV	RESULTLEN, #05
	RET
;-------------------------

;**********************************
;------------- SUB  PID mode select Line1-----------------------
LINE1:
	MOV	A, #LCD_SETDDADDR+0h	;Line1
	CALL	WRCMD

	MOV	A, PID1
	CJNE	A, #04h, $+9
	MOV	DPTR, #PID04
	JMP	LINE12
	CJNE	A, #05h, $+9
	MOV	DPTR, #PID05
	JMP	LINE12
	CJNE	A, #06h, $+9
	MOV	DPTR, #PID06
	JMP	LINE12
	CJNE	A, #07h, $+9
	MOV	DPTR, #PID07
	JMP	LINE12
	CJNE	A, #0Ah, $+9
	MOV	DPTR, #PID0A
	JMP	LINE12
	CJNE	A, #0Bh, $+9
	MOV	DPTR, #PID0B
	JMP	LINE12
	CJNE	A, #0Ch, $+9
	MOV	DPTR, #PID0C
	JMP	LINE12
	CJNE	A, #0Dh, $+9
	MOV	DPTR, #PID0D
	JMP	LINE12
	CJNE	A, #0Eh, $+9
	MOV	DPTR, #PID0E
	JMP	LINE12
	CJNE	A, #0Fh, $+9
	MOV	DPTR, #PID0F
	JMP	LINE12
	CJNE	A, #10h, $+9
	MOV	DPTR, #PID10
	JMP	LINE12
	CJNE	A, #11h, $+9
	MOV	DPTR, #PID11
	JMP	LINE12
	CJNE	A, #14h, $+9
	MOV	DPTR, #PID14
	JMP	LINE12
	CJNE	A, #15h, $+9
	MOV	DPTR, #PID15
	JMP	LINE12
	CJNE	A, #22h, $+9
	MOV	DPTR, #TFT
	JMP	LINE12
	CJNE	A, #23h, $+9
	MOV	DPTR, #PID23
	JMP	LINE12
	CJNE	A, #2Ch, $+9
	MOV	DPTR, #PID2C
	JMP	LINE12
	CJNE	A, #2Dh, $+9
	MOV	DPTR, #PID2D
	JMP	LINE12
	CJNE	A, #2Eh, $+9
	MOV	DPTR, #PID2E
	JMP	LINE12
	CJNE	A, #2Fh, $+9
	MOV	DPTR, #PID2F
	JMP	LINE12
	CJNE	A, #33h, $+9
	MOV	DPTR, #PID33
	JMP	LINE12
	CJNE	A, #3Ch, $+9
	MOV	DPTR, #PID3C
	JMP	LINE12
	CJNE	A, #3Dh, $+9
	MOV	DPTR, #PID3D
	JMP	LINE12
	CJNE	A, #42h, $+9
	MOV	DPTR, #PID42
	JMP	LINE12
	CJNE	A, #43h, $+9
	MOV	DPTR, #PID43
	JMP	LINE12
	CJNE	A, #44h, $+9
	MOV	DPTR, #PID44
	JMP	LINE12
	CJNE	A, #45h, $+9
	MOV	DPTR, #PID45
	JMP	LINE12
	CJNE	A, #46h, $+9
	MOV	DPTR, #PID46
	JMP	LINE12
	CJNE	A, #5Ch, $+9
	MOV	DPTR, #PID5C
	JMP	LINE12
	MOV	DPTR, #NODATA
LINE12:
	CALL	WRSTR		;write to LCD 1 Line
	MOV	WRADDL1, R1	;keep write address from R1
	RET
;*************************************
;---SUB  PID mode select Line2
LINE2:
	MOV	A, #LCD_SETDDADDR+40h	;Line2
	CALL	WRCMD

	MOV	A, PID2
	CJNE	A, #04h, $+9
	MOV	DPTR, #PID04
	JMP	LINE22
	CJNE	A, #05h, $+9
	MOV	DPTR, #PID05
	JMP	LINE22
	CJNE	A, #06h, $+9
	MOV	DPTR, #PID06
	JMP	LINE22
	CJNE	A, #07h, $+9
	MOV	DPTR, #PID07
	JMP	LINE22
	CJNE	A, #0Ah, $+9
	MOV	DPTR, #PID0A
	JMP	LINE22
	CJNE	A, #0Bh, $+9
	MOV	DPTR, #PID0B
	JMP	LINE22
	CJNE	A, #0Ch, $+9
	MOV	DPTR, #PID0C
	JMP	LINE22
	CJNE	A, #0Dh, $+9
	MOV	DPTR, #PID0D
	JMP	LINE22
	CJNE	A, #0Eh, $+9
	MOV	DPTR, #PID0E
	JMP	LINE22
	CJNE	A, #0Fh, $+9
	MOV	DPTR, #PID0F
	JMP	LINE22
	CJNE	A, #10h, $+9
	MOV	DPTR, #PID10
	JMP	LINE22
	CJNE	A, #11h, $+9
	MOV	DPTR, #PID11
	JMP	LINE22
	CJNE	A, #14h, $+9
	MOV	DPTR, #PID14
	JMP	LINE22
	CJNE	A, #15h, $+9
	MOV	DPTR, #PID15
	JMP	LINE22
	CJNE	A, #22h, $+9
	MOV	DPTR, #TFT
	JMP	LINE22
	CJNE	A, #23h, $+9
	MOV	DPTR, #PID23
	JMP	LINE22
	CJNE	A, #2Ch, $+9
	MOV	DPTR, #PID2C
	JMP	LINE22
	CJNE	A, #2Dh, $+9
	MOV	DPTR, #PID2D
	JMP	LINE22
	CJNE	A, #2Eh, $+9
	MOV	DPTR, #PID2E
	JMP	LINE22
	CJNE	A, #2Fh, $+9
	MOV	DPTR, #PID2F
	JMP	LINE22
	CJNE	A, #33h, $+9
	MOV	DPTR, #PID33
	JMP	LINE22
	CJNE	A, #3Ch, $+9
	MOV	DPTR, #PID3C
	JMP	LINE22
	CJNE	A, #3Dh, $+9
	MOV	DPTR, #PID3D
	JMP	LINE22
	CJNE	A, #42h, $+9
	MOV	DPTR, #PID42
	JMP	LINE22
	CJNE	A, #43h, $+9
	MOV	DPTR, #PID43
	JMP	LINE22
	CJNE	A, #44h, $+9
	MOV	DPTR, #PID44
	JMP	LINE22
	CJNE	A, #45h, $+9
	MOV	DPTR, #PID45
	JMP	LINE22
	CJNE	A, #46h, $+9
	MOV	DPTR, #PID46
	JMP	LINE22
	CJNE	A, #5Ch, $+9
	MOV	DPTR, #PID5C
	JMP	LINE12
	MOV	DPTR, #NODATA
LINE22:
	CALL	WRSTR		;Write to LCD Line2
	MOV	WRADDL2, R1	;keep write address from R1
	RET
;-----------------------
;Write string line to LCD & read WRADDR sub routine (INPUT   MOV DPTR,#xxxxx)
;Uses R0 for pointer R1 for WRADDR
WRSTR:
	MOV	R0, #BUFFER
WRSTR1:				;Load string to buffer
	CLR	A
	MOVC	A, @A+DPTR	;read from table
	MOV	@R0, A
	CJNE	A, #0Dh, $+6
	JMP	WRSTR2
	INC	DPTR
	INC	R0
	JMP	WRSTR1
WRSTR2:				;write buffer to LCD
	INC	R0
	MOV	@R0, #0Dh
	INC	DPTR
	CLR	A
	MOVC	A, @A+DPTR
	MOV	R1, A		; for use to write calculated data to any DDRAM address
	MOV	R0, #BUFFER	;point to buffer
WRSTR3:
	MOV	A, @R0		; A = data in iram
	CJNE	A, #0Dh, $+4
	RET			;return back
;write char to LCD
	SETB	EN
	NOP
	SETB	RS
	NOP
	MOV	LCDDATA, A
	NOP
	CLR	EN
	CALL	DEL5m
;-----
	INC	R0		;next char
	JMP	WRSTR3
;********************************
;Write & Scroll string line to LCD sub routine (INPUT   MOV DPTR,#xxxxx)
WRSCR:
	MOV	R0, #BUFFER
WRSCR1:				;Load string to buffer
	CLR	A
	MOVC	A, @A+DPTR	;read from table
	MOV	@R0, A
	CJNE	A, #0Dh, $+6
	JMP	WRSCR2
	INC	DPTR
	INC	R0
	JMP	WRSCR1
WRSCR2:				;write buffer to LCD
	INC	R0
	MOV	@R0, #0Dh
	MOV	R0, #BUFFER	;point to buffer
WRSCR3:
	MOV	A, @R0		; A = data in iram
	CJNE	A, #0Dh, $+4
	RET
;write char to LCD
	SETB	EN
	NOP
	SETB	RS
	NOP
	MOV	LCDDATA, A
	NOP
	CLR	EN
	CALL	DEL100m
;-----
	INC	R0		;next char
	JMP	WRSCR3
;********************************
WRCMD:				;write command  INPUT ACC
	SETB	EN
	NOP
	CLR	RS
	NOP
	MOV	LCDDATA, A
	NOP
	CLR	EN
	CALL	DEL100m
	RET
;********************************
WRCHAR:				;wite data to LCD  INPUT ACC
	SETB	EN
	NOP
	SETB	RS
	NOP
	MOV	LCDDATA, A
	NOP
	CLR	EN
	CALL	DEL5m
	RET
;********************************
;get result in buffer and translate to B1,B2
;USE	R0,R1
;IN 	BUFFER
;OUT	B1,B2,PID
GETB1B2:
	MOV	A, BUFFER	;check 41 01 response first
	CJNE	A, #34h, MODE22	;If A = "4" then next else jump
	MOV	SLEEPCNT, #24h	;Reset sleep mode counter
	MOV	R0, #BUFFER+6	;point to byte1
	MOV	A, @R0
	CALL	ATOH		;translate 1st byte
	SWAP	A		;keep data in B7-B4
	MOV	B1, A		;keep B7-B4 in BYTE1
	INC	R0
	MOV	A, @R0
	CALL	ATOH		;translate 2nd byte
	MOV	R1, #B1		;point bo B1
	XCHD	A, @R1		;keep B3-B0 in BYTE1
;---Byte 1 Get OK
	MOV	R0, #BUFFER+9	;point to byte2
	MOV	A, @R0
	CALL	ATOH		;translate 1st byte
	SWAP	A		;keep data in B7-B4
	MOV	B2, A		;keep B7-B4 in BYTE1
	INC	R0
	MOV	A, @R0
	CALL	ATOH		;translate 2nd byte
	MOV	R1, #B2		;point bo B1
	XCHD	A, @R1		;keep B3-B0 in BYTE1
	RET
;*********adddition for TFT 221E1C******************
;respond 62 1E 1C B1 B2
MODE22:
	CJNE	A, #36h, PWRDOWN	;If A = "6" then next else jump
	MOV	SLEEPCNT, #24h	;Reset sleep mode counter
	MOV	R0, #BUFFER+9	;point to byte1
	MOV	A, @R0
	CALL	ATOH		;translate 1st byte
	SWAP	A		;keep data in B7-B4
	MOV	B1, A		;keep B7-B4 in BYTE1
	INC	R0
	MOV	A, @R0
	CALL	ATOH		;translate 2nd byte
	MOV	R1, #B1		;point bo B1
	XCHD	A, @R1		;keep B3-B0 in BYTE1
;---Byte 1 Get OK
	MOV	R0, #BUFFER+12	;point to byte2
	MOV	A, @R0
	CALL	ATOH		;translate 1st byte
	SWAP	A		;keep data in B7-B4
	MOV	B2, A		;keep B7-B4 in BYTE1
	INC	R0
	MOV	A, @R0
	CALL	ATOH		;translate 2nd byte
	MOV	R1, #B2		;point bo B1
	XCHD	A, @R1		;keep B3-B0 in BYTE1
	RET
;*******************************************

PWRDOWN:			;Error mesasge receive then goto sleep mode
	DJNZ	SLEEPCNT, NO_DATA
	MOV	A, CONFIG	;Check Auto sleep On or OFF
	JNB	ACC.4, NO_DATA	;If auto sleep mode is off then skip to NODATA
	CALL	SOUND_BEEP
	MOV	A, #LCD_CLS
	CALL	WRCMD
	CALL	DEL100m
	MOV	A, #LCD_SETDDADDR+0	;Line 1
	CALL	WRCMD
	MOV	DPTR, #PDOWN1	;Power Down Mode
	CALL	WRSTR
	MOV	A, #LCD_SETDDADDR+40h	;Line 2
	CALL	WRCMD
	MOV	DPTR, #PDOWN2	;Power Down Mode
	CALL	WRSTR
	CALL	DEL500m
	CALL	SOUND_TRIG
	CALL	DEL500m
	CALL	SOUND_TRIG
	CALL	DEL500m
	CALL	SOUND_TRIG
	CALL	DEL500m
	MOV	A, #LCD_SETVISIBLE+000b	; display off + nocursor + noblink
	CALL	WRCMD
	CLR	LEDUP		;turn off LED
	CLR	LEDDN
	SETB	BL		;Turn off Back light
;MOV	PCON,#02h	;set PCON.1 the power down...........
;System shut down here
	JMP	TURNONCHK
NO_DATA:
	MOV	B1, #00h
	MOV	B2, #00h
	RET
;check engine turn on again or not
TURNONCHK:
	MOV	DPTR, #CHKCAN
	CALL	SBLOCK
	CALL	RBYTE		;Receive "SEARCHING...."
	CJNE	A, #34h, $+12	;If A = "4" then start watch dog to make all reset
	MOV	DPTR, #SERWS	;send warm start message
	CALL	SBLOCK
	CALL	WDRESET		;All System Reset Here
	MOV	TEMP1, #10
DEL5SEC:
	CALL	DEL500m
	DJNZ	TEMP1, DEL5SEC
	JMP	TURNONCHK	;check turn on key again
;add some thing here
;------------- TFT send 221E1C---------
;IN =A
SEND221E1C:
	MOV	DPTR, #TFTPID
	CALL	SBLOCK
	RET
;-------------ASCII to HEX-----------------------------
;IN = A,R1
;OUT = A
ATOH:				;ASCII to Hex Converter
	MOV	B, #41h
	DIV	AB
	CJNE	A, #01h, ATOF2	;IF A=>B then goto ATOF2
	MOV	A, @R0		;data in buffer
	SUBB	A, #37h
	RET
ATOF2:
	MOV	A, @R0		;data in buffer
	SUBB	A, #2Fh
	RET
;--------------HexToASCII----------------
;IN = A,R7
;OUT = A
HTOA:
	MOV	R7, A
	MOV	B, #0Ah		;Hex value to ASCII Code Sub Routine Use ACC
	DIV	AB
	CJNE	A, #01h, ATOF	;If A=>B then goto ATOF
	MOV	A, R7
	ADD	A, #37h		;Result in A  (for 0 - 9)
	RET
ATOF:
	MOV	A, R7		;Return IRAM data to A
	ADD	A, #30h		;REsult in A  (for  A-F)
	RET
; ********** SBLOCK SUB **********
; SEND BLOCK
; IN  = DPTR ROM-ADDRESS (END BY 0 OR 0DH)
; OUT = DPTR (NEXT)
; REG = A,DPTR
SBLOCK:
	CLR	A
	MOVC	A, @A+DPTR
	JNZ	SBLOCK1
	RET			;EXIT BY 0
SBLOCK1:
	INC	DPTR		;next char
	CALL	SBYTE		;send char
	JMP	SBLOCK
;===========RBLOCK=========
; IN  = A
; OUT = BUFFER
; REG = R0,DPTR
RBLOCK:
	MOV	R0, #BUFFER	;R0 point to buffer memory address
RBLOCK1:
	CALL	RBYTE		;wait for incoming char
	CJNE	A, #3Eh, RBLOCK2	;If A = '>' then end message
	RET			;EXIT BY '>'
RBLOCK2:
	MOV	@R0, A		;Save char in buffer
	INC	R0		;point next address
	JMP	RBLOCK1
	; ----------------------------------
SBYTE:				;Send Data from RS232
	JNB	TI, $		;WAIT FOR SEND OK
	CLR	TI
	MOV	SBUF, A
	RET
;------------------------------------
RBYTE:				;Receive Data from RS232
	JNB	RI, $		;WAIT FOR RECEIVE OK
	CLR	RI
	MOV	A, SBUF
	RET
;-------- Delay 50 usec-----------------------------------
;USE = R6,R7
DEL5m:
	MOV	R6, #1Fh
	DJNZ	R6, $
	RET
;----------delay 0.5 sec-----------------------------
;USE = R4,R5,R6,R7
DEL500m:
	MOV	R4, #0Ah
DEL500m1:
	MOV	R5, #064h
DEL500m3:
	MOV	R7, #03h
DEL500m2:
	MOV	R6, #098h
	DJNZ	R6, $
	DJNZ	R7, DEL500m2
	DJNZ	R5, DEL500m3
	DJNZ	R4, DEL500m1
	RET
;----------delay 0.1 sec-----------------------------
;USE = R4,R5,R6,R7
DEL100m:
	MOV	R4, #02h
DEL100m1:
	MOV	R5, #032h
DEL100m3:
	MOV	R7, #03h
DEL100m2:
	MOV	R6, #098h
	DJNZ	R6, $
	DJNZ	R7, DEL100m2
	DJNZ	R5, DEL100m3
	DJNZ	R4, DEL100m1
	RET
;---------Hex to Dec------------------
;IN = DPTR		;FFFF
;OUT = R1,R2,R3		;R1=6  R2=55 R3=35
;REG = A,R0,R1-R5,DPTR
HTOD:
	MOV	A, #00h
	MOV	R1, A
	MOV	R2, A
	MOV	R3, A
	MOV	R4, #16
HTOD1:
	MOV	A, DPL
	RLC	A
	MOV	DPL, A
	MOV	A, DPH
	RLC	A
	MOV	DPH, A
	MOV	R5, #3
	MOV	R0, #3
HTOD2:
	MOV	A, @R0
	ADDC	A, ACC
	DA	A
	MOV	@R0, A
	DEC	R0
	DJNZ	R5, HTOD2
	DJNZ	R4, HTOD1
	RET
;********************************
SOUND_BEEP:
	CLR	BUZZER		;buzzer on
	MOV	R3, #07h
DELS1:
	MOV	R4, #0FFh
SOUND_BEEP1:
	MOV	R5, #0FFh
	DJNZ	R5, $
	DJNZ	R4, SOUND_BEEP1
	DJNZ	R3, DELS1
	SETB	BUZZER		;buzzer off
	RET
;************************************************
SOUND_TRIG:
	MOV	A, CONFIG
	JB	ACC.1, SOUND_TRIG0	;If BEEP on Do next
	CALL	DEL100m		;delay compensate trig loop
	RET
SOUND_TRIG0:
	CLR	BUZZER		;buzzer on
	MOV	R3, #030h	;SOUND LOOP
SOUND_TRIG1:
	MOV	R4, #0FFh
	DJNZ	R4, $
	DJNZ	R3, SOUND_TRIG1	;NEXT LOOP
	SETB	BUZZER		;buzzer off
	RET			;back to main routine	
;**********************************************
BACKLIGHT:			;toggle back light
	JB	BL, BACKLIGHT2
	SETB	BL		;turn off
	CALL	DEL500m
	RET
BACKLIGHT2:
	CLR	BL		;turn on
	CALL	DEL500m
	RET
;*********************************************
LIGHT1:				;warning light up  checking compare value by diviation 
	MOV	A, CONFIG	;check PID warning lamp status on/off
	JNB	ACC.3, LIGHT11	;off then jump LIGHT11
;INPUT current pid in ACC 
	MOV	A, B1		;load first byte only
	MOV	B, LIMITCHK1
	DIV	AB
	MOV	R7, A		;keep result in R7
	MOV	A, PID1
	CJNE	A, #0Ah, $+6
	JMP	LOWLIMIT1
	CJNE	A, #014h, $+6
	JMP	LOWLIMIT1
	CJNE	A, #015h, $+6
	JMP	LOWLIMIT1
	CJNE	A, #02Fh, $+6
	JMP	LOWLIMIT1
	CJNE	A, #042h, $+6
	JMP	LOWLIMIT1
;check high limit
	MOV	A, R7		;return RESULT
	JZ	LIGHT11		;if A>0 then OK  , if A=0 then Over limit-> warning on
	SETB	LEDUP
LIGHT11:
	CLR	LEDDN		;off LEDDN
	RET
LOWLIMIT1:			;check lowlimit
	MOV	A, R7
	JNZ	LIGHT11		;if A = 0 then lower limit -> warning on
	SETB	LEDUP
	CLR	LEDDN		;off LEDDN
	RET
;*********************************************
LIGHT2:				;warning light down checking
	MOV	A, CONFIG	;check PID warning lamp status on/off
	JNB	ACC.3, LIGHT22	;off then jump LIGHT22
;INPUT current pid in ACC
	MOV	A, B1		;load first byte only
	MOV	B, LIMITCHK2
	DIV	AB
	MOV	R7, A		;keep result in R7
	MOV	A, PID2
	CJNE	A, #0Ah, $+6
	JMP	LOWLIMIT2
	CJNE	A, #014h, $+6
	JMP	LOWLIMIT2
	CJNE	A, #015h, $+6
	JMP	LOWLIMIT2
	CJNE	A, #02Fh, $+6
	JMP	LOWLIMIT2
	CJNE	A, #042h, $+6
	JMP	LOWLIMIT2
;check high limit
	MOV	A, R7		;return RESULT
	JZ	LIGHT22		;if A>0 then OK  , if A=0 then Over limit-> warning on
	SETB	LEDDN
LIGHT22:
	CLR	LEDUP		;off LEDDN
	RET
LOWLIMIT2:			;check lowlimit
	MOV	A, R7
	JNZ	LIGHT22		;if A = 0 then lower limit -> warning on
	SETB	LEDDN
	CLR	LEDUP		;off LEDDN
	RET
;*********************************************

; subroutine UDIV16
; 16-Bit / 16-Bit to 16-Bit Quotient & Remainder Unsigned Divide
;
; input:    r1, r0 = Dividend X
;           r3, r2 = Divisor Y
;
; output:   r1, r0 = quotient Q of division Q = X / Y
;           r3, r2 = remainder 
;
; alters:   acc, B, dpl, dph, r4, r5, r6, r7, flags
;====================================================================

UDIV16:	mov	r7, #0		; clear partial remainder
	mov	r6, #0
	mov	B, #16		; set loop count

div_loop:	clr	C	; clear carry flag
	mov	a, r0		; shift the highest bit of
	rlc	a		; the dividend into...
	mov	r0, a
	mov	a, r1
	rlc	a
	mov	r1, a
	mov	a, r6		; ... the lowest bit of the
	rlc	a		; partial remainder
	mov	r6, a
	mov	a, r7
	rlc	a
	mov	r7, a
	mov	a, r6		; trial subtract divisor
	clr	C		; from partial remainder
	subb	a, r2
	mov	dpl, a
	mov	a, r7
	subb	a, r3
	mov	dph, a
	cpl	C		; complement external borrow
	jnc	div_1		; update partial remainder if
	; borrow
	mov	r7, dph		; update partial remainder
	mov	r6, dpl
div_1:	mov	a, r4		; shift result bit into partial
	rlc	a		; quotient
	mov	r4, a
	mov	a, r5
	rlc	a
	mov	r5, a
	djnz	B, div_loop
	mov	a, r5		; put quotient in r0, and r1
	mov	r1, a
	mov	a, r4
	mov	r0, a
	mov	a, r7		; get remainder, saved before the
	mov	r3, a		; last subtraction
	mov	a, r6
	mov	r2, a
	ret
;===================================================
; subroutine UMUL16
; 16-Bit x 16-Bit to 32-Bit Product Unsigned Multiply
;
; input:    r1, r0 = multiplicand X
;           r3, r2 = multiplier Y
;
; output:   r3, r2, r1, r0 = product P = X x Y
;
; alters:   acc, C
;====================================================================

UMUL16:	push	B
	push	dpl
	mov	a, r0
	mov	b, r2
	mul	ab		; multiply XL x YL
	push	acc		; stack result low byte
	push	b		; stack result high byte
	mov	a, r0
	mov	b, r3
	mul	ab		; multiply XL x YH
	pop	00H
	add	a, r0
	mov	r0, a
	clr	a
	addc	a, b
	mov	dpl, a
	mov	a, r2
	mov	b, r1
	mul	ab		; multiply XH x YL
	add	a, r0
	mov	r0, a
	mov	a, dpl
	addc	a, b
	mov	dpl, a
	clr	a
	addc	a, #0
	push	acc		; save intermediate carry
	mov	a, r3
	mov	b, r1
	mul	ab		; multiply XH x YH
	add	a, dpl
	mov	r2, a
	pop	acc		; retrieve carry
	addc	a, b
	mov	r3, a
	mov	r1, 00H
	pop	00H		; retrieve result low byte
	pop	dpl
	pop	B
	ret
;====================================================================
; subroutine ADD16
; 16-Bit Signed (2's Complement) Addition
;
; input:     r1, r0 = X
;            r3, r2 = Y
;
; output:    r1, r0 = signed sum S = X + Y
;            Carry C is set if the result (S) is out of range
;
; alters:    acc, C, OV
;====================================================================
ADD16:	anl	PSW, #0E7H	; Register Bank 0
	mov	a, r0		; load X low byte into acc
	add	a, r2		; add Y low byte
	mov	r0, a		; put result in Z low byte
	mov	a, r1		; load X high byte into acc
	addc	a, r3		; add Y high byte with carry
	mov	r1, a		; save result in Z high byte
	mov	C, OV
	ret
;====================================================================
;EEPROM 24LC01B  Sub Routine
; ********** IPW SUB **********
; 24LC01B WRITE
;IN   	 R0=  ADDRESS,   R1 = DATA
;OUT	 EEPERR  0=OK 1=ERROR
; REG = A,R2
IPW:
;CLR	EEPWP		;disable write protect
	CALL	CDEL		;delay
	SETB	EEPSDA		;START CONDITION
	SETB	EEPSCL
	CLR	EEPSDA
	CALL	CDEL
	CLR	EEPSCL
	SETB	EEPSDA
	MOV	A, #10100000B	;Write Control Code  1010AAAW
	CALL	IPWRB		;1 Byte Write
	JB	EEPERR, IPW9
	MOV	A, R0		;WORD ADDRESS
	ANL	A, #01111111B	;Limit Address to 128 byte only
	CALL	IPWRB		;1 Byte Write
	JB	EEPERR, IPW9
	MOV	A, R1		;DATA
	CALL	IPWRB		;1 Byte Write
IPW9:
	CLR	EEPSDA		;STOP CONDITION
	SETB	EEPSCL
	CALL	CDEL
	SETB	EEPSDA
;SETB	EEPWP		;ENable write protech
	RET
; ********** IPWRB SUB **********
; 24LC01B WRITE 1 BYTE
; IN  = A
; OUT = EEPERR  0=OK 1=ERROR
; REG = A,R2
IPWRB:
	CLR	EEPERR		;Reset Error Byte
	MOV	R2, #8
IPWRB1:
	RLC	A
	MOV	EEPSDA, C
	CALL	CHIGH		;CLOCK
	CALL	CLOW
	DJNZ	R2, IPWRB1
	SETB	EEPSDA		;ACKNOWLEDGE BIT
	CALL	CHIGH
	JNB	EEPSDA, IPWRB2
	SETB	EEPERR
IPWRB2:
	CALL	CLOW
	RET
; ********** IPR SUB **********
;24LC01B READ
;IN  = R0  ADDRESS
;OUT = R1  DATA
; EEPERR  0=OK 1=ERROR
; REG = A,R2
IPR:
	SETB	EEPSDA		;START CONDITION
	SETB	EEPSCL
	CLR	EEPSDA
	CALL	CDEL
	CLR	EEPSCL
	MOV	A, #10100000B	;DEVICE ADDRESS 1010AAAW
	CALL	IPWRB
	JB	EEPERR, IPR9
	MOV	A, R0		;WORD ADDRESS
	ANL	A, #01111111B
	CALL	IPWRB
	JB	EEPERR, IPR9
	CLR	EEPSDA		;STOP CONDITION
	SETB	EEPSCL
	CALL	CDEL
	SETB	EEPSDA
	SETB	EEPSDA		;START CONDITION
	SETB	EEPSCL
	CLR	EEPSDA
	CALL	CDEL
	CLR	EEPSCL
	MOV	A, #10100001B	;DEVICE ADDRESS 1010AAAR
	CALL	IPWRB
	JB	EEPERR, IPR9
	CALL	IPRDB		;Read DATA
	JB	EEPERR, IPR9
	MOV	R1, A
IPR9:
	CLR	EEPSDA		;STOP CONDITION
	SETB	EEPSCL
	CALL	CDEL
	SETB	EEPSDA
	RET
; ********** IPRDB SUB **********
; READ BYTE
; OUT = A
; EEPERR  0=OK 1=ERROR
; REG = A,R2
IPRDB:
	CLR	EEPERR		;reset Error Byte
	MOV	R2, #8
IPRDB1:
	CALL	CHIGH
	MOV	C, EEPSDA
	RLC	A
	CALL	CLOW
	DJNZ	R2, IPRDB1
	SETB	EEPSDA		;ACKNOWLEDGE BIT (1)
	CALL	CHIGH
	JB	EEPSDA, IPRDB2
	SETB	EEPERR
IPRDB2:
	CALL	CLOW
	RET
;********EEPROM Clock***************
CHIGH:
	SETB	EEPSCL		;**** SCL HIGH + DELAY ****
	NOP
	NOP
	NOP
	NOP
	NOP
	RET

CLOW:
	CLR	EEPSCL		;**** SCL LOW + DELAY ****
	NOP
	NOP
	NOP
	NOP
	NOP
	RET

CDEL:
	NOP			;**** DELAY ****
	NOP
	NOP
	NOP
	NOP
	RET
;================================================
WDRESET:			;Reset watchdog timer 
	MOV	WDTRST, #01Eh
	MOV	WDTRST, #0E1h
	RET
;------------------------------------------------------------------
;Interprete trouble code
;IN = R0  OUT = R1,R2
INTPDTC:
	CJNE	@R0, #30h, $+8
	MOV	R1, #50h	;P char
	MOV	R2, #30h	;0 char
	RET
	CJNE	@R0, #31h, $+8
	MOV	R1, #50h	;P char
	MOV	R2, #31h	;1 char
	RET
	CJNE	@R0, #32h, $+8
	MOV	R1, #50h	;P char
	MOV	R2, #32h	;2 char
	RET
	CJNE	@R0, #33h, $+8
	MOV	R1, #50h	;P char
	MOV	R2, #33h	;3 char
	RET
	CJNE	@R0, #34h, $+8
	MOV	R1, #43h	;C char
	MOV	R2, #30h	;0 char
	RET
	CJNE	@R0, #35h, $+8
	MOV	R1, #43h	;C char
	MOV	R2, #31h	;1 char
	RET
	CJNE	@R0, #36h, $+8
	MOV	R1, #43h	;C char
	MOV	R2, #32h	;2 char
	RET
	CJNE	@R0, #37h, $+8
	MOV	R1, #43h	;C char
	MOV	R2, #33h	;3 char
	RET
	CJNE	@R0, #38h, $+8
	MOV	R1, #42h	;B char
	MOV	R2, #30h	;0 char
	RET
	CJNE	@R0, #39h, $+8
	MOV	R1, #42h	;B char
	MOV	R2, #31h	;1 char
	RET
	CJNE	@R0, #41h, $+8
	MOV	R1, #42h	;B char
	MOV	R2, #32h	;2 char
	RET
	CJNE	@R0, #42h, $+8
	MOV	R1, #42h	;B char
	MOV	R2, #33h	;3 char
	RET
	CJNE	@R0, #43h, $+8
	MOV	R1, #55h	;U char
	MOV	R2, #30h	;0 char
	RET
	CJNE	@R0, #44h, $+8
	MOV	R1, #55h	;U char
	MOV	R2, #31h	;1 char
	RET
	CJNE	@R0, #45h, $+8
	MOV	R1, #55h	;U char
	MOV	R2, #32h	;2 char
	RET
	CJNE	@R0, #46h, $+8
	MOV	R1, #55h	;U char
	MOV	R2, #33h	;3 char
	RET
;================================================
;Looking Table
CHKCAN:	DB	"0100", 0Dh, 00h	;PID send to check CAN connection
SERINIT1:	DB	"ATE0", 0Dh, 00h	;set Echo off
SERINIT2:	DB	"ATL0", 0Dh, 00h	;set Lind Feed off
SERINIT3:	DB	"ATH0", 0Dh, 00h	;set Msg Header  off
SERINIT4:	DB	"ATST00", 0DH, 00h	;set wait time = 4 msec
SERINIT5:	DB	"ATSPA6", 0Dh, 00h	;set Default CAN Bus and auto search
SERWS:	DB	"ATWS", 0Dh, 00h	;ELM warm start message
TITLE1:	DB	00h, 01h, 02h, "OBDII X-METER V1", 0Dh
TITLE2:	DB	03h, 04h, 05h, "----------------", 0Dh
TITLE3:	DB	"Createdby Ratthanin", 06h, 0Dh, 00h

MENU1:	DB	"SelectSETUP Menu[~]", 0Dh, 00h
MENU11:	DB	"1.Auto Backlight   ", 0Dh, 00h
MENU12:	DB	"2. Set SPEAKER     ", 0Dh, 00h
MENU13:	DB	"3. Set start-up PID1", 0Dh, 00h
MENU14:	DB	"4. Set start-up PID2", 0Dh, 00h
MENU15:	DB	"5. PID Warning Light", 0Dh, 00h
MENU16:	DB	"6. Auto Sleep Mode.", 0Dh, 00h
MENU17:	DB	"7. Firmware Ver 1.07", 0Dh, 00h
RELEASE:	DB	"Nov25, 2022|JavaJacob", 00Dh, 00h

MENU2:	DB	"SpecialFunction [~]", 0Dh, 00h
VEHINFO:	DB	"1.Veh Info Numbers:", 0Dh, 00h
DTC:	DB	"2.No. of DTCs = -- ", 0Dh, 16
MILOFF:	DB	"MILstatus is OFF...", 0Dh, 00h
MILON:	DB	"Pressto read DTC[~]", 0Dh, 00h
SETMIL:	DB	"ClearMIL now?[NO ]~", 0Dh, 00h
DTCPID:	DB	"0101", 0Dh, 00h	;for SBLOCK  check no of DTC
DTCREAD:	DB	"03", 0Dh, 00h	;for SBLOCK  read DTC
DISPDTC:	DB	"next DTC[~]", 0Dh, 00h
CLRMIL:	DB	"04", 0Dh, 00h	;for SBLOCK  clear MIL status
TOGGLE:	DB	"Press to set[~]", 0Dh, 00h

LIMITMSG:	DB	"[SET LIMITTED VALUE]", 0Dh, 00h
LIMITFIN:	DB	"Setting complete!...", 0Dh, 00h
UGFIRM1:	DB	"[ UPGRADE FIRMWARE ]", 0Dh, 00h
UGFIRM2:	DB	"Waiting connection.", 0Dh, 00h
UGFIRM3:	DB	"Now Upgrading...    ", 0Dh, 00h

SPDPID:	DB	"010D", 0Dh, 00h	;for SBLOCK fuel consumption calculate
MAFPID:	DB	"0110", 0Dh, 00h
TFTPID:	DB	"221E1C", 0Dh, 00h	;Transmission Fluid Temperature PID 

CGDegC:	DB	08h, 14h, 08h, 03h, 04h, 04h, 04h, 03h, 0Dh, 00h	;degree C symbol
CGDegF:	DB	08h, 14h, 08h, 07h, 05h, 06h, 04h, 04h, 0Dh, 00h	;degree F symbol
CGUL:	DB	00h, 00h, 01h, 06h, 08h, 0Ch, 1Bh, 10h, 0Dh, 00h
CGUM:	DB	00h, 00h, 1Fh, 00h, 00h, 00h, 11h, 0Ah, 0Dh, 00h
CGUR:	DB	00h, 00h, 10h, 0Ch, 02h, 06h, 1Bh, 01h, 0Dh, 00h
CGLL:	DB	10h, 10h, 08h, 0Eh, 03h, 00h, 00h, 00h, 0Dh, 00h
CGLM:	DB	04h, 04h, 00h, 00h, 11h, 1Fh, 00h, 00h, 0Dh, 00h
CGLR:	DB	01h, 01h, 02h, 0Eh, 18h, 00h, 00h, 00h, 0Dh, 00h

PID04:	DB	"CAL Engine Load ---%", 0Dh, 16
PID05:	DB	"Coolant Temp: --- ", 0DFh, "c", 0Dh, 14
PID06:	DB	"S-T Fuel Trim1 --- %", 0Dh, 15
PID07:	DB	"L-T Fuel Trim1 --- %", 0Dh, 15

PID0A:	DB	"Fuel Pressure ---kPa", 0Dh, 14
PID0B:	DB	"MAN Air Press ---kPa", 0Dh, 14
PID0C:	DB	"ENG Speed: ---- RPM ", 0Dh, 11
PID0D:	DB	"VEH Speed: --- km/h ", 0Dh, 11
PID0E:	DB	"IGN ADV Timing: ---", 0DFh, 0Dh, 16
PID0F:	DB	"Intake Air Temp --", 0DFh, "c", 0Dh, 15
PID10:	DB	"Air Flow ---.- g/sec", 0Dh, 9
PID11:	DB	"Throttle Pos: --- %  ", 0Dh, 14
PID14:	DB	"Front HO2S Volt -.--", 0Dh, 16
PID15:	DB	"Rear  HO2S Volt -.--", 0Dh, 16

PID23:	DB	"Rail Press ---.- MPa", 0Dh, 11	;((A*256)+B) /100
PID2C:	DB	"Commanded EGR: --- %", 0Dh, 15
PID2D:	DB	"EGRError: --- %    ", 0Dh, 11
PID2E:	DB	"CMDEvap Purge --- %", 0Dh, 15
PID2F:	DB	"Fuel Level: --- %   ", 0Dh, 12

PID33:	DB	"Baro Pressure ---kPa", 0Dh, 14

PID3C:	DB	"CAT 1 Temp: ---.- ", 0DFh, "c", 0Dh, 12
PID3D:	DB	"CAT 2 Temp: ---.- ", 0DFh, "c", 0Dh, 12

PID42:	DB	"PCM Voltage: --.-- V", 0Dh, 13
PID43:	DB	"ABS Engine Load ---%", 0Dh, 16
PID44:	DB	"CMD EQV Ratio: -.--   ", 0Dh, 15
PID45:	DB	"REL Throt Pos: --- %", 0Dh, 15
PID46:	DB	"AMB Air Temp: --- ", 0DFh, "c", 0Dh, 14
PID5C:	DB	"ENG Oil Temp: --- ", 0DFh, "c", 0Dh, 14

TFT:	DB	"Trans Fluid ---.- ", 0DFh, "c", 0Dh, 12

NODATA:	DB	"", 0Dh, 00
SPDMAF:	DB	"--- km/h|AF --.- g/s", 0Dh, 00h
INSTFC:	DB	"Current F/C --.-km/L", 0Dh, 00h
AVRFC:	DB	"Average F/C --.-km/L", 0Dh, 00h
RDERR:	DB	"EEPROM Reading Error", 0Dh, 00h
WRERR:	DB	"EEPROM Writing Error", 0Dh, 00h
PDOWN1:	DB	"Engine is turned off", 0Dh, 00h
PDOWN2:	DB	"Switch to SLEEP mode", 0Dh, 00h

	END