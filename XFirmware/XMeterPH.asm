;Program Test LCD
;ATMEL89S52
;$INCLUDE"RegMSC51.asm"

;SOUND_TRIG   	EQU 8280h
;SOUND_BEEP  	EQU 8200h
;HEXTOSEG	EQU 8400h

PID1		EQU	08h	;PID1 mode
PID2		EQU	09h	;PID2 mode
PIDTURN		EQU	0Ah	;check which PID will be sent to ELM
WRADDL1	EQU	0Bh	;LCD write address for calculated value line1
WRADDL2	EQU	0Ch	;LCD write address for calculated value line2
B1		EQU	0Dh	;address for Byte1
B2		EQU	0Eh	;address for Byte2
RESULTLEN	EQU	0Fh	;keep length of result
CONFIG		EQU	10h	; bit0 = 1 beepon, 0=beep off/
TEMP1		EQU 	11h	;general ram use
TEMP2		EQU	12h	;general ram use
TEMP3		EQU	13h	;general ram use
BUFFER		EQU	20h	;Message Buffer

;LCD Registers addresses		; A0(W/R)  A1 (Data/Inst)
DIGBL		EQU	0F000h	;Display digit & Black Light
LCD_CMD_WR	EQU 	08000h	
LCD_DATA_WR	EQU	08002h	
LCD_BUSY_RD	EQU	08001h
LCD_DATA_RD	EQU	08003h

;LCD Commands Write parameter   
;MOV A = parameter then CALL LCD_CMD_WR
LCD_CLS		EQU	01
LCD_HOME	EQU	02
LCD_SETMODE	EQU	04    ;+I/D  S
;I/D  = 0 Cursor&DDRAM  Decrement  , I/D = 1 Cursor&DDRAM Increment
;S   = 0   Cursor Move as I/D, S =1  insert charactor
LCD_SETVISIBLE	EQU	08    ;+ D C B
;D = 0 Off display ,D = 1 On display
;C = 0 Off Cur sor , C = 1 On cursor
;B = 0 Blink Off    ,  B = 1 Blink On
LCD_SHIFT	EQU	16 ; + S/C  R/L  x  x
;S/C = 0 move cursor as R/L  1 position
;S/C = 1 move charactor as R/L 1 column on every line
;R/L = 0 Left direction, R/L = 1 Right direction
LCD_SETFUNC	EQU	32; + DL  N  F  x  x
;DL = 0  4 bit mode , DL = 1  8 bit mode
;N = 0  1/8 Duty   ,N = 1 1/16 duty
;F = 0   5x7 dot,   F = 1  5x10 dot
LCD_SETCGADDR	EQU	64 ; + address  upto 16 data
LCD_SETDDADDR	EQU	128 ; + address
;Program Start Address 
ORG  	 7000h  

;*****RESET START*******************************
;RES:
;MOV	  R0,#7FH           ;POWER UP CLEAR 61-7FH
;RES1:    
;MOV	  @R0,#0
;DEC	  R0
;CJNE	  R0,#00H,RES1	;Clear IRAM Adress 00h-7Fh = 0
MOV  	  B,#0              ;CLEAR SYSTEM FLAG
MOV	  SP,#40h        ;SET STACK point to IRAM (not duplicate)
;Serial Port initialize
MOV	PCON,#80H          	 ;1000000  19200 for AT89C2051 = 0 then 9600
MOV  	TMOD,#20H        	 ;TIMER1 MODE2
MOV         TH1,#0FDH  	  ;19200
MOV	SCON,#52H 	  ;SERIAL 8 BIT UART MODE
SETB	TR1             	  ;TIMER1 ON
CLR	ES		;no interrupt
;Variable Init
MOV	PID1,#04h
MOV	PID2,#04h
MOV	PIDTURN,#01h	;set to PID1 current msg
MOV	CONFIG,#00000001	;beep on
;===========================
;Load CGRAM
MOV	A,#LCD_SETCGADDR+0  ;set CDRAM address
CALL	WRCMD
MOV	DPTR,#CGUL
CALL	WRSTR		;write 3 char in CGRAM  05
MOV	DPTR,#CGUM
CALL	WRSTR		;write 3 char in CGRAM  06
MOV	DPTR,#CGUR
CALL	WRSTR		;write 3 char in CGRAM  07
MOV	DPTR,#CGLL
CALL	WRSTR		;write 3 char in CGRAM  08
MOV	DPTR,#CGLM	
CALL	WRSTR		;write 3 char in CGRAM  09
MOV	DPTR,#CGLR
CALL	WRSTR		;write 3 char in CGRAM  0Ah
MOV	DPTR,#CGD	;Load D char
CALL	WRSTR		;write D char in CGRAM  0Eh
MOV	DPTR,#CGM	;Load 3 char
CALL	WRSTR		;write 3 char in CGRAM  0Fh

;add more here

;LCD Initialize
CALL	LCDBLON		;Back Light on
MOV	A,#LCD_CLS
CALL	WRCMD
CALL	DEL100m
MOV	A,#LCD_SETFUNC+11000b 
CALL	WRCMD
MOV	A,#LCD_SETVISIBLE+100b      ; display on + nocursor + noblink
CALL	WRCMD
MOV	A,#LCD_SHIFT+0000b 
CALL	WRCMD
MOV	A,#LCD_SETMODE+11b	 ;Left scroll
CALL	WRCMD
;==============================
;LCD display title
MOV	A,#LCD_SETDDADDR+00 ;Line 1
CALL	WRCMD
MOV	DPTR,#TITLE1
CALL	WRSCR
MOV	A,#LCD_SETDDADDR+40h ;Line2
CALL	WRCMD
MOV	DPTR,#TITLE2
CALL	WRSCR
;------------
MOV	A,#LCD_SETMODE+10b 
CALL	WRCMD
;Checking system
CALL	DEL500m
CALL	DEL500m
CALL	DEL500m
CALL	DEL500m
MOV	A,#LCD_CLS	;clear screen once
CALL	WRCMD
CALL	DEL100m
;----------- connecting display
CALL	SOUND_TRIG
MOV	A,#LCD_SETDDADDR+0 ;Line 1
CALL	WRCMD
MOV	DPTR,#TITLE3
CALL	WRSTR
MOV	A,#LCD_SETVISIBLE+101b      ; display on + nocursor + blinking
CALL	WRCMD

;===============================
;ELM327 Initialize message
MOV	DPTR,#SERINIT1
CALL	SBLOCK
CALL	DEL100m
MOV	DPTR,#SERINIT2
CALL	SBLOCK
CALL	DEL100m
MOV	DPTR,#SERINIT3
CALL	SBLOCK
CALL	DEL100m
MOV	DPTR,#SERINIT4
CALL	SBLOCK
CALL	DEL100m
MOV	DPTR,#SERINIT5
CALL	SBLOCK
;check CAN connection
TRYCAN:
MOV	A,#LCD_SETDDADDR+40h ;Line2
CALL	WRCMD
MOV	DPTR,#CHKCAN	;send 4100 to ELM327
CALL	SBLOCK
;Receive "SEARCHING...."
MOV	A,#3Eh		;send ">" first
TRYCAN1:
CALL	WRCHAR
CALL	RBYTE
CJNE	A,#0Dh,TRYCAN1	;until A = CR
MOV	A,#LCD_SETDDADDR+40h 	;set address to line2
CALL	WRCMD
MOV	DPTR,#NODATA	;clear LCD line2
CALL	WRSTR
MOV	A,#LCD_SETDDADDR+40h 	;set address to line2
CALL	WRCMD
;Read Result
MOV	A,#3Eh		;send ">" first
TRYCAN2:
CALL	WRCHAR
CALL	RBYTE
CJNE	A,#34h,TRYCAN3	;If A = "4" then connection OK
JMP	CONNECT
;check 4100 or not
TRYCAN3:
CJNE	A,#0Dh,TRYCAN2	;if A = CR wait 2 second  and try again
CALL	DEL500m
CALL	DEL500m
CALL	DEL500m
CALL	DEL500m
JMP	TRYCAN		;request again

CONNECT:
;loop to check > feed back
CALL	RBYTE
CJNE	A,#3Eh,$-3	;ELM connected OK
MOV	A,#LCD_SETVISIBLE+100b      ; display on + nocursor + noblink
CALL	WRCMD
;---------------------------------	
;load old PID1&PID2 and send AT command
;MOV	PID1,#04h	;PID mode from memory
;MOV	PID2,#04h	;PID mode from memory
METER:
CALL	LINE1		;first line PID display
CALL	LINE2		;second line PID display
;send AT command
;*************** MAIN LOOP **********************************
MOV	A,#0Dh	
CALL	SBYTE		;send CR to receive > and start receive data
MAIN:			;Main Loop
;***** check PID mode and send command to ELM and show string to LCD

JB	RI,RECEIVE	;read back data from ELM
;***** PID mode change button check**********
MAIN3:
JB	INT0,MAIN2	;next mode Line1
CALL	DEL100m	;keyboard delay
CALL	DEL100m	;keyboard delay
JNB	INT1,SETUP0	;jump to setup mode
CALL	SOUND_TRIG
INC	PID1		;add pid1+1
MOV	A,PID1
CALL	SKIPPID		;skip unused PID mode
MOV	PID1,A		;Return skipped PID mode
CALL	LINE1
;addition
MOV	A,#0Dh		;send CR again 
CALL	SBYTE
JMP	MAIN
;------------
MAIN2:
JB	INT1,MAIN	;next mode Line2
CALL	DEL100m	;keyboard delay
CALL	DEL100m	;keyboard delay
CALL	SOUND_TRIG
INC	PID2		;add pid1+1
MOV	A,PID2
CALL	SKIPPID		;skip unused PID mode
MOV	PID2,A		;Return skipped PID mode
CALL	LINE2		;Update LCD 
;adddition
MOV	A,#0Dh
CALL	SBYTE
JMP	MAIN
SETUP0:
JMP	SETUP
;-------------------------------------
RECEIVE:
CALL	RBLOCK
MOV	A,PIDTURN
CJNE	A,#01h,PIDTURN2	;if PIDTURN<> 1 then goto PIDTURN2
;LCD LINE1**********************************
;CALL	LINE1		;Display PID mode in LINE1
CALL	GETB1B2		;Translate ASCII in buffer to Hex Data and keep in B1,B2
MOV	R2,PID1		;keep PID1 mode in R2 for CALCULATE
CALL	CALCULATE	;Determine PID mode / calculate /translate to ASCII / keep in BUFFER/RESULTLEN
;------Write Result to LCD lin1
MOV	A,#LCD_SETDDADDR 	;set address in LCD to write result in LINE1
ADD	A,WRADDL1		;add write address
CALL	WRCMD
MOV	R1,RESULTLEN		;R1 = Length of result to display
MOV	R0,#BUFFER		;R0 point to buffer
LENGTH1:
MOV	A,@R0			;load char in A
CALL	WRCHAR
INC	R0
DJNZ	R1,LENGTH1		;loop til end of length
;check PID2 mode & send AT cmd to ELM
MOV	PIDTURN,#02h	;set  PIDTURN = 2
MOV	A,#30h
CALL	SBYTE	;send char0
MOV	A,#31h
CALL	SBYTE	;send char1
MOV	A,PID2	;keep pid2 in temp
SWAP	A
ANL	A,#0Fh
MOV	R1,A
CALL	HTOA
CALL	SBYTE	;send higt byte
MOV	A,PID2	;keep pid2 in temp
ANL	A,#0Fh
MOV	R1,A
CALL	HTOA
CALL	SBYTE	;send low byte
MOV	A,#0Dh
CALL	SBYTE	;send CR
JMP	MAIN3
;LINE2********************************************
PIDTURN2:
;CALL	LINE2		;Display PID mode in LINE2
CALL	GETB1B2		;Translate ASCII in buffer to Hex Data and keep in B1,B2
MOV	R2,PID2		;keep PID2 mode in R2 for CALCULATE
CALL	CALCULATE	;Determine PID mode / calculate /translate to ASCII / keep in BUFFER/RESULTLEN
;-------Write Result to LCD lin2
MOV	A,#LCD_SETDDADDR+40h 	;set address in LCD to write result in LINE2
ADD	A,WRADDL2
CALL	WRCMD
MOV	R1,RESULTLEN		;R1 = Length of result to display
MOV	R0,#BUFFER		;R0 point to buffer
LENGTH2:
MOV	A,@R0			;load char in A
CALL	WRCHAR
INC	R0
DJNZ	R1,LENGTH2		;loop til end of length
;check PID1 mode & send AT cmd to ELM
MOV	PIDTURN,#01h	;set PIDTURN = 1
MOV	A,#30h
CALL	SBYTE	;send char0
MOV	A,#31h
CALL	SBYTE	;send char1
MOV	A,PID1	;keep pid1 in temp
SWAP	A
ANL	A,#0Fh
MOV	R1,A
CALL	HTOA
CALL	SBYTE	;send higt byte
MOV	A,PID1	;keep pid1 in temp
ANL	A,#0Fh
MOV	R1,A
CALL	HTOA
CALL	SBYTE	;send low byte
MOV	A,#0Dh
CALL	SBYTE	;send CR
JMP	MAIN3
;********************END of Program*****************************
CONSUMP0:
JMP	CONSUMP

SETUP:     ; test setup menu
CALL	SOUND_BEEP
MOV	R4,#0Ah 
DEL5m1:
MOV	R5,#064h
DEL5m3:
MOV	R7,#03h
DEL5m2:
MOV	R6,#098h
JB	INT0,CONSUMP0	;goto fuel consumption mode
DJNZ	R6,$-3
DJNZ	R7,DEL5m2
DJNZ       R5,DEL5m3
DJNZ	R4,DEL5m1	;end delay loop 

MOV	A,#LCD_SETDDADDR+00 ;Line 1
CALL	WRCMD
MOV	DPTR,#MENU1
CALL	WRSTR
MOV	A,#LCD_SETDDADDR+40h ;Line2
CALL	WRCMD
MOV	DPTR,#MENU2
CALL	WRSTR
CALL	DEL500m		;delay 
CALL	DEL500m
;select mode here
;Vehicel info
JB	INT0,$
CALL	DEL100m
CALL	DEL100m
CALL	SOUND_TRIG
MOV	A,#LCD_CLS
CALL	WRCMD
CALL	DEL100m
MOV	A,#LCD_SETDDADDR+00 ;Line 1
CALL	WRCMD
MOV	DPTR,#VEHINFO	;vehicale info
CALL	WRSTR
;add code for receive vehinfo and send result in line2
;----------------------
;NO of DTC
JB	INT0,$
CALL	DEL100m
CALL	DEL100m
CALL	SOUND_TRIG
MOV	A,#LCD_CLS
CALL	WRCMD
CALL	DEL100m
MOV	A,#LCD_SETDDADDR+00 ;Line 1
CALL	WRCMD
MOV	DPTR,#DTC	;no. of DTC
CALL	WRSTR
MOV	DPTR,#DTCPID
CALL	SBLOCK		;send 0101
CALL	RBLOCK		;receive result from ELM
CALL	GETB1B2		;get Byte1 Byte2
MOV	A,B1
SUBB	A,#80h		;A - 80h = DTC no.
MOV	B1,A		;keep no. DTC in B1
JZ	PIDCOUNT	;if MIL off jump PIDCOUNT
MOV	A,#LCD_SETDDADDR+40h	;set to Line2
CALL	WRCMD
MOV	DPTR,#MILON
CALL	WRSTR
PIDCOUNT:
MOV	DPTR,#0000h
MOV	DPL,B1
CALL	HTOD		;Result in R3
MOV	A,#LCD_SETDDADDR+17	;set cursor position
CALl	WRCMD
MOV	A,R3
SWAP	A		;get High nibble
ANL	A,#0Fh		
ADD	A,#30h
CALL	WRCHAR		;write 1st digit
MOV	A,R3
ANL	A,#0Fh
ADD	A,#30h
CALL	WRCHAR		;write 2nd digit
;----------------------
;Beep ON/OFF
JB	INT0,$
CALL	DEL100m
CALL	DEL100m
CALL	SOUND_TRIG
MOV	A,#LCD_CLS
CALL	WRCMD
CALL	DEL100m
MOV	A,#LCD_SETDDADDR+00 ;Line 1
CALL	WRCMD
MOV	DPTR,#BEEP	;set BEEP on/OFF
CALL	WRSTR
MOV	A,#LCD_SETDDADDR+40 ;Line 1
CALL	WRCMD
MOV	DPTR,#TOGGLE	;TOGGLE Here
CALL	WRSTR
BEEPSTATUS:
MOV	A,#LCD_SETDDADDR+40 ;Line 1 set address to write ON or OFF
CALL	WRCMD
MOV	A,CONFIG		;check beep on/off status
JNB	ACC.0,BEEPOFF	;goto beep off
MOV	A,#4Fh		;O char
CALL	WRCHAR
MOV	A,#4Eh		;N char
CALL	WRCHAR
MOV	A,#20h		;space char
CALL	WRCHAR
JMP	SETBEEP		;jump to set beep
BEEPOFF:
MOV	A,#4Fh		;O char
CALL	WRCHAR
MOV	A,#46h		;F char
CALL	WRCHAR
MOV	A,#46h		;F char
CALL	WRCHAR
SETBEEP:
JNB	INT0,SETUPEXIT	;press to exit setup
JB	INT1,SETBEEP
CALL	DEL500m	;keyboard delay
MOV	A,CONFIG
CPL	ACC.0		;toggle value
MOV	CONFIG,A
JMP	BEEPSTATUS	;refresh status
SETUPEXIT:
CALL	DEL500m
CALL	DEL500m	;key delay
JMP	METER
;******************END CONFIG************
CONSUMP:
MOV	A,#LCD_CLS
CALL	WRCMD
CALL	DEL100m
MOV	A,#LCD_SETDDADDR+00 ;Line 1
CALL	WRCMD
MOV	DPTR,#SPDMAF
CALL	WRSTR
MOV	A,#LCD_SETDDADDR+40h ;Line 2
CALL	WRCMD
MOV	DPTR,#CONSUM
CALL	WRSTR
CONSUMP2:	;calculate loop
;---veh speed
MOV	DPTR,#SPDPID
CALL	SBLOCK		;send 010D to ELM
CALL	RBLOCK
CALL	GETB1B2	
MOV	TEMP1,B1	;keep speed in temp1
CALL	FORMULA3	;calculate speed result in BUFFER
MOV	A,#LCD_SETDDADDR+0	;set cursot line1 
CALL	WRCMD
MOV	R1,RESULTLEN
MOV	R0,#BUFFER	;point to buffer
VEHSPD:
MOV	A,@R0			;load char in A
CALL	WRCHAR
INC	R0
DJNZ	R1,VEHSPD		;loop til end of length
;---MAF
MOV	DPTR,#MAFPID
CALL	SBLOCK		;send 010D to ELM
CALL	RBLOCK
CALL	GETB1B2	
MOV	TEMP2,B1	;keep airflow in temp2
MOV	TEMP3,B2	;keep airflow in temp3
CALL	AIRFLOW		;calculate airflow result in buffer
MOV	A,#LCD_SETDDADDR+12	;set cursot line1 
CALL	WRCMD
MOV	R1,RESULTLEN
MOV	R0,#BUFFER	;point to buffer
MAF:
MOV	A,@R0			;load char in A
CALL	WRCHAR
INC	R0
DJNZ	R1,MAF		;loop til end of length
;calculate fuel consumption & display on Line 2
;FC = (speed x 1Dhx0Ah)/ (Airflow /0Ah)
MOV	R1,TEMP2	;Airflow /0Ah
MOV	R0,TEMP3
MOV	R3,#00h
MOV	R2,#0Ah
CALL	UDIV16		;result in R1,R0
MOV	TEMP2,R1
MOV	TEMP3,R0

MOV	R1,#00h
MOV	R0,TEMP1		;Speed x 1Dhx0Ah
MOV	R3,#01h
MOV	R2,#22h
CALL	UMUL16		;result in R3,R2,R1,R0 (use only R1 R0)
MOV	R3,TEMP2	;prepare divider
MOV	R2,TEMP3

CALL	UDIV16		;result in R1,R0
;end FC calculate
MOV	DPH,R1
MOV	DPL,R0
CALL	HTOD		;convert result to DEC
MOV	A,#LCD_SETDDADDR+76	;set cursot line1 
CALL	WRCMD
MOV	A,R2
ANL	A,#0Fh
JZ	FCZERO
ADD	A,#30h		;change to ascii
JMP	FCNONZERO
FCZERO:
MOV	A,#17h		;space
FCNONZERO:
CALL	WRCHAR		;write 1 st digit
MOV	A,R3
SWAP	A
ANL	A,#0Fh
ADD	A,#30h
CALL	WRCHAR		;write 2nd digit
MOV	A,#2Eh		
CALL	WRCHAR		;write full stop
MOV	A,R3
ANL	A,#0Fh
ADD	A,#30h
CALL	WRCHAR		;write 3nd digit
;end calculation fuel consumption
JB	INT0,CONSUMP3	;jump back to calculte consump
JB	INT1,CONSUMP3
CALL	SOUND_TRIG
CALL	DEL500m
CALL	DEL500m	;key delay
JMP	METER		;Exit
CONSUMP3:
JMP	CONSUMP2
;============SUB ROUTINE=======================
;SKIP PID  IN A(PID mode) OUT  A and PID
SKIPPID:
CJNE	A,#08h,$+6
MOV	A,#0Ah
RET
CJNE	A,#12h,$+6
MOV	A,#2Ch
RET
CJNE	A,#30h,$+6
MOV	A,#33h
RET
CJNE	A,#34h,$+6
MOV	A,#3Ch
RET
CJNE	A,#3Eh,$+6
MOV	A,#42h
RET
CJNE	A,#47h,$+5
MOV	A,#04h
RET
;*********************************
;IN   B1,B2 ,R2
;OUT   BUFFER,RESULTLEN
CALCULATE:  ;Determine PID mode / calculate /translate to ASCII / keep in BUFFER/RESULTLEN

CJNE	R2,#04h,$+7	;CAL Engine Load
CALL	FORMULA1
RET
CJNE	R2,#05h,$+7	;Coolant Temp
CALL	FORMULA2
RET
CJNE	R2,#06h,$+7	;Short Term Fuel TRim B1
CALL	FUELTRIM
RET
CJNE	R2,#07h,$+7	;Long Term Fuel Trim B1
CALL	FUELTRIM
RET
CJNE	R2,#0Ah,$+7	;Fuel Pressure
CALL	FORMULA3
RET
CJNE	R2,#0Bh,$+7	;MAN air Press
CALL	FORMULA3
RET
CJNE	R2,#0Ch,$+7	;ENG Speed
CALL	ENGSPEED
RET
CJNE	R2,#0Dh,$+7	;VEH Speed
CALL	FORMULA3
RET
CJNE	R2,#0Eh,$+7	;IGN ADV Timing
CALL	IGNTIME
RET
CJNE	R2,#0Fh,$+7	;Intake Air Temp
CALL	FORMULA2
RET
CJNE	R2,#10h,$+7	;Air Flow
CALL	AIRFLOW
RET
CJNE	R2,#11h,$+7	;Throttle Pos
CALL	FORMULA1
RET
CJNE	R2,#2Ch,$+7	;Command EGR
CALL	FORMULA1
RET
CJNE	R2,#2Dh,$+7	;EGR error
CALL	FORMULA1
RET
CJNE	R2,#2Eh,$+7	;Command Evap Purge
CALL	FORMULA1
RET
CJNE	R2,#2Fh,$+7	;Fuel Level
CALL	FORMULA1
RET
CJNE	R2,#33h,$+7	;Baro Press
CALL	FORMULA3
RET
CJNE	R2,#3Ch,$+7	;CAT 1 Temp
CALL	CATTEMP
RET
CJNE	R2,#3Dh,$+7	;CAT 2 Temp
CALL	CATTEMP
RET
CJNE	R2,#42h,$+7	;ECU Volt
CALL	ECUVOLT
RET
CJNE	R2,#43h,$+7	;ABS ENgine load
CALL	FORMULA1
RET
CJNE	R2,#44h,$+7	;CMD EQV RAtio
CALL	CMDEQV
RET
CJNE	R2,#45h,$+7	;REL Throt Pos
CALL	FORMULA1
RET
CJNE	R2,#46h,$+6	;AMB Air Temp
CALL	FORMULA2
RET
;***********************************
;--SUB Formula Caculation---------------------------------------
;IN   B1,B2
;OUT BUFFER, RESULTLEN
FORMULA1:	;Percentage calculate B1/255 x 100
MOV	A,B1
MOV	B,#100
MUL	AB	;result in BA
MOV	DPTR,#0000h
MOV	DPL,A
CALL	HTOD	;Result fraction A keep in R2,R3  take only R2 low nibble
MOV	A,R2	;keep carry in A
MOV	DPTR,#0000h
MOV	DPL,B	;take byte1 
ADD	A,B	;add byte1 with carry 
MOV	DPTR,#000h	;final result for HTOD
MOV	DPL,A
CALL	HTOD	;Result in R2,R2

MOV	A,R2
ANL	A,#0Fh
MOV	R4,A	;keep
JZ	$+9	;IF A = 0 then skip to BUFFER = #17h
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER,A	;digit1
JMP	$+6
MOV	BUFFER,#17h	;Result is 0 then put SPACE
MOV	A,R3
SWAP	A
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+1,A	;digit2
MOV	A,R3
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+2,A	;digit1
MOV	RESULTLEN,#03
RET
;------------------
FORMULA2:	;Temperature B1-40
MOV	DPTR,#0000h
MOV	A,B1
CLR	C
SUBB	A,#40
MOV	DPL,A
CALL	HTOD
MOV	A,R2
ANL	A,#0Fh
JZ	$+9	;IF A = 0 then skip to BUFFER = #17h
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER,A	;digit1
JMP	$+6
MOV	BUFFER,#17h	;Result is 0 then put SPACE
MOV	A,R3
SWAP	A
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+1,A	;digit2
MOV	A,R3
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+2,A	;digit1
MOV	RESULTLEN,#03
RET
;------------------
FORMULA3:	;direct byte
MOV	DPTR,#0000h
MOV	DPL,B1
CALL	HTOD	;convert hex to Decimal (R1,R2,R3)
MOV	A,R2
ANL	A,#0Fh
JZ	$+9	;IF A = 0 then skip to BUFFER = #17h
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER,A	;digit1
JMP	$+6
MOV	BUFFER,#17h	;Result is 0 then put SPACE
MOV	A,R3
SWAP	A
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+1,A	;digit2
MOV	A,R3
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+2,A	;digit1
MOV	RESULTLEN,#03
RET
;--------------------
FUELTRIM:	;( B1x64h)/80h - 64h
MOV	A,B1
MOV	B,#64h
MUL	AB	;Result in B,A
MOV	R1,B
MOV	R0,A
MOV	R3,#00
MOV	R2,#80h
CALL	UDIV16	;Result in R1,R0
CLR	C	;clear carry flag
MOV	A,R0
SUBB	A,#64h	;Result in ACC
;Sign checking
JC	$+9	; OV set then negative sign
MOV	BUFFER,#2Bh	;+sign
JMP	POSFT
MOV	BUFFER,#2Dh	;-Sign
MOV	R4,A
MOV	A,#64h
SUBB	A,R4		;64h - A
POSFT:
MOV	DPTR,#0000h
MOV	DPL,A
CALL	HTOD	;convert hex to Decimal (R1,R2,R3)
MOV	A,R3
SWAP	A
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+1,A	;digit2
MOV	A,R3
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+2,A	;digit1
MOV	RESULTLEN,#03
RET
;--------------------
ENGSPEED:	;[(B1x256) + B2] / 4
MOV	A,B1
MOV	B,#04h
DIV	AB	;B1/4  fraction in B
MOV	DPH,A	;keep A in DPH
MOV	A,#40h	
MUL	AB	;A = B x #40h   Result in BA
MOV	R4,A	;keep result in R4
MOV	A,B2	
MOV	B,#04h
DIV	AB
ADD	A,R4	;B2/4 + R4
MOV	DPL,A	;keep A in DPL
CALL	HTOD	;Result  in R2,R3 then convert to ASCII
MOV	A,R2	;digit1
SWAP	A
ANL	A,#0Fh
JZ	$+9	;IF A = 0 then skip to BUFFER = #17h
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER,A	;digit1
JMP	$+6
MOV	BUFFER,#17h	;Result is 0 then put SPACE
MOV	A,R2	;digit2
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+1,A	;digit2
MOV	A,R3	;digit3
SWAP	A
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+2,A	;digit3
MOV	A,R3	;digit4
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+3,A	;digit4
MOV	RESULTLEN,#04
RET
;-------------------
IGNTIME:		;(B1 / 2) -64h
MOV 	A,B1
MOV	B,#02h
DIV	AB
CLR	C
SUBB	A,#64
;Sign checking
JC	$+9	; OV set then negative sign
MOV	BUFFER,#2Bh	;+sign
JMP	POS
MOV	BUFFER,#2Dh	;-Sign
MOV	R4,A
MOV	A,#0FFh
SUBB	A,R4
ADD	A,#02h		;correction

POS:
MOV	DPTR,#0000h
MOV	DPL,A
MOV	R4,A		;keep A in R4
CALL	HTOD	;convert hex to Decimal (R1,R2,R3)
MOV	A,R3
SWAP	A
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+1,A	;digit2
MOV	A,R3
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+2,A	;digit1
MOV	RESULTLEN,#03
RET
;-------------------------
AIRFLOW:		;[(B1x256)+B2]/100
MOV	DPH,B1
MOV	DPL,B2	;keep A in DPL
CALL	HTOD	;Result  in R2,R3 then convert to ASCII
MOV	A,R1	;digit1
JZ	$+9	;IF A = 0 then skip to BUFFER = #17h
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER,A	;digit1
JMP	$+6
MOV	BUFFER,#17h	;Result is 0 then put SPACE
MOV	A,R2	;digit2
SWAP	A
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+1,A
MOV	A,R2	;digit4
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+2,A	;digit2
MOV	A,R3	;digit5
SWAP	A
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+4,A	;digit3
MOV	BUFFER+3,#2Eh	;full stop
MOV	RESULTLEN,#05
RET
;-------------------------
CATTEMP:	;[(B1x256)+B2]/10
MOV	DPH,B1
MOV	DPL,B2
CALL	HTOD	;Result  in R2,R3 then convert to ASCII
MOV	A,R2	;digit1
SWAP	A
ANL	A,#0Fh
JZ	$+9	;IF A = 0 then skip to BUFFER = #17h
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER,A	;digit1
JMP	$+6
MOV	BUFFER,#17h	;Result is 0 then put SPACE
MOV	A,R2	;digit2
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+1,A	;digit2
MOV	A,R3	;digit3
SWAP	A
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+2,A	;digit3
MOV	A,R3	;digit4
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+4,A	;digit4
MOV	BUFFER+3,#2Eh	;full stop
MOV	RESULTLEN,#05
RET
;-------------------------
ECUVOLT:	;[(B1x256)+B2]/1000
MOV	DPH,B1
MOV	DPL,B2	;keep A in DPL
CALL	HTOD	;Result  in R2,R3 then convert to ASCII
MOV	A,R1	;digit1
JZ	$+9	;IF A = 0 then skip to BUFFER = #17h
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER,A	;digit1
JMP	$+6
MOV	BUFFER,#17h	;Result is 0 then put SPACE
MOV	A,R2	;digit2
SWAP	A
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+1,A	;digit2
MOV	A,R2	;digit4
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+3,A	;digit2
MOV	A,R3	;digit5
SWAP	A
ANL	A,#0Fh
ADD	A,#30h	;convert dec to ASCII
MOV	BUFFER+4,A	;digit3
MOV	BUFFER+2,#2Eh	;full stop
MOV	RESULTLEN,#05
RET
CMDEQV:		;calculate commanded equivalent ratio B1B2 / 8000h
MOV	R1,B1
MOV	R0,B2
MOV	R3,#01h
MOV	R2,#47h
CALL	UDIV16    ; {B1B2 / 147h} Result in R1,R0
MOV	DPH,R1
MOV	DPL,R0
CALL	HTOD	;convert to decimal resultin R1,R2,R3
MOV	A,R2
ADD	A,#30h
MOV	BUFFER,A	;1st digit
MOV	BUFFER+1,#2Eh	;full stop
MOV	A,R3
ANL	A,#0Fh
ADD	A,#30h
MOV	BUFFER+3,A	;3rd digit
MOV	A,R3
SWAP	A
ANL	A,#0Fh
ADD	A,#30h
MOV	BUFFER+2,A	;2nd digit
MOV	RESULTLEN,#04
RET
;**********************************
;------------- SUB  PID mode select Line1-----------------------
LINE1:
MOV	A,#LCD_SETDDADDR+0h ;Line1
CALL	WRCMD

MOV	A,PID1
CJNE	A,#04h,$+9
MOV	DPTR,#PID04
JMP	LINE12
CJNE	A,#05h,$+9
MOV	DPTR,#PID05
JMP	LINE12
CJNE	A,#06h,$+9
MOV	DPTR,#PID06
JMP	LINE12
CJNE	A,#07h,$+9
MOV	DPTR,#PID07
JMP	LINE12
CJNE	A,#0Ah,$+9
MOV	DPTR,#PID0A
JMP	LINE12
CJNE	A,#0Bh,$+9
MOV	DPTR,#PID0B
JMP	LINE12
CJNE	A,#0Ch,$+9
MOV	DPTR,#PID0C
JMP	LINE12
CJNE	A,#0Dh,$+9
MOV	DPTR,#PID0D
JMP	LINE12
CJNE	A,#0Eh,$+9
MOV	DPTR,#PID0E
JMP	LINE12
CJNE	A,#0Fh,$+9
MOV	DPTR,#PID0F
JMP	LINE12
CJNE	A,#10h,$+9
MOV	DPTR,#PID10
JMP	LINE12
CJNE	A,#11h,$+9
MOV	DPTR,#PID11
JMP	LINE12
CJNE	A,#2Ch,$+9
MOV	DPTR,#PID2C
JMP	LINE12
CJNE	A,#2Dh,$+9
MOV	DPTR,#PID2D
JMP	LINE12
CJNE	A,#2Eh,$+9
MOV	DPTR,#PID2E
JMP	LINE12
CJNE	A,#2Fh,$+9
MOV	DPTR,#PID2F
JMP	LINE12
CJNE	A,#33h,$+9
MOV	DPTR,#PID33
JMP	LINE12
CJNE	A,#3Ch,$+9
MOV	DPTR,#PID3C
JMP	LINE12
CJNE	A,#3Dh,$+9
MOV	DPTR,#PID3D
JMP	LINE12
CJNE	A,#42h,$+9
MOV	DPTR,#PID42
JMP	LINE12
CJNE	A,#43h,$+9
MOV	DPTR,#PID43
JMP	LINE12
CJNE	A,#44h,$+9
MOV	DPTR,#PID44
JMP	LINE12
CJNE	A,#45h,$+9
MOV	DPTR,#PID45
JMP	LINE12
CJNE	A,#46h,$+9
MOV	DPTR,#PID46
JMP	LINE12
MOV	DPTR,#NODATA
LINE12:
CALL	WRSTR		;write to LCD 1 Line
MOV	WRADDL1,R1	;keep write address from R1
RET
;*************************************
;---SUB  PID mode select Line2
LINE2:
MOV	A,#LCD_SETDDADDR+40h ;Line2
CALL	WRCMD

MOV	A,PID2
CJNE	A,#04h,$+9
MOV	DPTR,#PID04
JMP	LINE22
CJNE	A,#05h,$+9
MOV	DPTR,#PID05
JMP	LINE22
CJNE	A,#06h,$+9
MOV	DPTR,#PID06
JMP	LINE22
CJNE	A,#07h,$+9
MOV	DPTR,#PID07
JMP	LINE22
CJNE	A,#0Ah,$+9
MOV	DPTR,#PID0A
JMP	LINE22
CJNE	A,#0Bh,$+9
MOV	DPTR,#PID0B
JMP	LINE22
CJNE	A,#0Ch,$+9
MOV	DPTR,#PID0C
JMP	LINE22
CJNE	A,#0Dh,$+9
MOV	DPTR,#PID0D
JMP	LINE22
CJNE	A,#0Eh,$+9
MOV	DPTR,#PID0E
JMP	LINE22
CJNE	A,#0Fh,$+9
MOV	DPTR,#PID0F
JMP	LINE22
CJNE	A,#10h,$+9
MOV	DPTR,#PID10
JMP	LINE22
CJNE	A,#11h,$+9
MOV	DPTR,#PID11
JMP	LINE22
CJNE	A,#2Ch,$+9
MOV	DPTR,#PID2C
JMP	LINE22
CJNE	A,#2Dh,$+9
MOV	DPTR,#PID2D
JMP	LINE22
CJNE	A,#2Eh,$+9
MOV	DPTR,#PID2E
JMP	LINE22
CJNE	A,#2Fh,$+9
MOV	DPTR,#PID2F
JMP	LINE22
CJNE	A,#33h,$+9
MOV	DPTR,#PID33
JMP	LINE22
CJNE	A,#3Ch,$+9
MOV	DPTR,#PID3C
JMP	LINE22
CJNE	A,#3Dh,$+9
MOV	DPTR,#PID3D
JMP	LINE22
CJNE	A,#42h,$+9
MOV	DPTR,#PID42
JMP	LINE22
CJNE	A,#43h,$+9
MOV	DPTR,#PID43
JMP	LINE22
CJNE	A,#44h,$+9
MOV	DPTR,#PID44
JMP	LINE22
CJNE	A,#45h,$+9
MOV	DPTR,#PID45
JMP	LINE22
CJNE	A,#46h,$+9
MOV	DPTR,#PID46
JMP	LINE22
MOV	DPTR,#NODATA
LINE22:
CALL	WRSTR		;Write to LCD Line2
MOV	WRADDL2,R1	;keep write address from R1
RET
;-----------------------
;Write string line to LCD & read WRADDR sub routine (INPUT   MOV DPTR,#xxxxx)
;Uses R0 for pointer R1 for WRADDR
WRSTR:
MOV	R0,#BUFFER	
WRSTR1:	;Load string to buffer
CLR	 A
MOVC	 A,@A+DPTR	;read from table
MOV	@R0,A
CJNE	 A,#0Dh,$+6
JMP	WRSTR2
INC	DPTR
INC	R0
JMP	WRSTR1

WRSTR2:  ;write buffer to LCD
INC	R0
MOV	@R0,#0Dh
INC	DPTR
CLR	A
MOVC	 A,@A+DPTR
MOV	R1,A	; for use to write calculated data to any DDRAM address
MOV	R0,#BUFFER	;point to buffer
MOV	DPTR,#LCD_DATA_WR	;point to LCD data write address
WRSTR3:
MOV	A,@R0		; A = data in iram
CJNE	A,#0Dh,$+6	
JMP	WRSTR4
MOVX	@DPTR,A		;write data to LCD DATA WR address
INC	R0		;next char
CALL	DEL5m
JMP	WRSTR3
WRSTR4:
RET
;********************************
;Write & Scroll string line to LCD sub routine (INPUT   MOV DPTR,#xxxxx)
WRSCR:
MOV	R0,#BUFFER	
WRSCR1:	;Load string to buffer
CLR	 A
MOVC	 A,@A+DPTR	;read from table
MOV	@R0,A
CJNE	 A,#0Dh,$+6
JMP	WRSCR2
INC	DPTR
INC	R0
JMP	WRSCR1

WRSCR2:  ;write buffer to LCD
INC	R0
MOV	@R0,#0Dh
MOV	R0,#BUFFER	;point to buffer
MOV	DPTR,#LCD_DATA_WR	;point to LCD data write address
WRSCR3:
MOV	A,@R0		; A = data in iram
CJNE	A,#0Dh,$+6	
JMP	WRSCR4
MOVX	@DPTR,A		;write data to LCD DATA WR address
INC	R0		;next char
CALL	DEL100m
JMP	WRSCR3
WRSCR4:
RET
;********************************
LCDBLON:
CLR 	 ACC.4		         ;SOUND BIT = LOW
MOV	 DPTR,#DIGBL
MOVX   	@DPTR,A
RET
;********************************
LCDBLOFF:
SETB  	 ACC.4		         ;SOUND BIT = LOW
MOV	 DPTR,#DIGBL
MOVX   	@DPTR,A
RET
;********************************
WRCMD:	;write command  INPUT ACC
MOV	DPTR,#LCD_CMD_WR
MOVX	@DPTR,A
CALL	DEL5m
RET
;********************************
WRCHAR: ;wite data to LCD
MOV	DPTR,#LCD_DATA_WR
MOVX	@DPTR,A
CALL	DEL5m
RET
;********************************
;get result in buffer and translate to B1,B2
;USE	R0,R1
;IN 	BUFFER
;OUT	B1,B2,PID
GETB1B2:
MOV	A,BUFFER	;check 41 01 response first
CJNE	A,#34h,BADDATA	;If A = "4" then next else jump
MOV	R0,#BUFFER+6	;point to byte1
MOV	A,@R0
CALL	ATOH		;translate 1st byte
SWAP	A		;keep data in B7-B4
MOV	B1,A		;keep B7-B4 in BYTE1
INC	R0
MOV	A,@R0
CALL	ATOH		;translate 2nd byte
MOV	R1,#B1		;point bo B1
XCHD	A,@R1		;keep B3-B0 in BYTE1
;---Byte 1 Get OK
MOV	R0,#BUFFER+9	;point to byte2
MOV	A,@R0
CALL	ATOH		;translate 1st byte
SWAP	A		;keep data in B7-B4
MOV	B2,A		;keep B7-B4 in BYTE1
INC	R0
MOV	A,@R0
CALL	ATOH		;translate 2nd byte
MOV	R1,#B2		;point bo B1
XCHD	A,@R1		;keep B3-B0 in BYTE1
RET
BADDATA:
MOV	B1,#00h
MOV	B2,#00h
RET
;-------------ASCII to HEX-----------------------------
;IN = A,R1
;OUT = A
ATOH:			;ASCII to Hex Converter
MOV	B,#41h		
DIV	AB
CJNE	A,#01h,ATOF2	;IF A=>B then goto ATOF2
MOV	A,@R0		;data in buffer
SUBB	A,#37h
RET
ATOF2:
MOV	A,@R0		;data in buffer
SUBB	A,#2Fh
RET		 
;--------------HexToASCII----------------
;IN = A,R1
;OUT = A
HTOA:
MOV	B,#0Ah		;Hex value to ASCII Code Sub Routine Use ACC
DIV	AB
CJNE	A,#01h,ATOF	;If A=>B then goto ATOF
MOV	A,R1
ADD	A,#37h		;Result in A  (for 0 - 9)
RET
ATOF:
MOV	A,R1		;Return IRAM data to A
ADD	A,#30h		;REsult in A  (for  A-F)
RET
; ********** SBLOCK SUB **********
; SEND BLOCK
; IN  = DPTR ROM-ADDRESS (END BY 0 OR 0DH)
; OUT = DPTR (NEXT)
; REG = A,DPTR
SBLOCK:
CLR	 A
MOVC 	 A,@A+DPTR
JNZ	SBLOCK1
RET                      		;EXIT BY 0
SBLOCK1:
INC	DPTR		;next char
CALL	SBYTE		;send char
JMP	SBLOCK
;===========RBLOCK=========
; IN  = A
; OUT = BUFFER
; REG = R0,DPTR
RBLOCK:
MOV	R0,#BUFFER	;R0 point to buffer memory address
RBLOCK1:
CALL	RBYTE		;wait for incoming char
CJNE	A,#3Eh,RBLOCK2	;If A = '>' then end message
RET                      		;EXIT BY '>'
RBLOCK2:
MOV	@R0,A		;Save char in buffer
INC	R0		;point next address
JMP	RBLOCK1
 ; ----------------------------------
SBYTE:   			;Send Data from RS232
JNB 	TI,$    	 	;WAIT FOR SEND OK
CLR 	TI
MOV        SBUF,A
RET
;------------------------------------
RBYTE:			;Receive Data from RS232
JNB    	RI,$                ;WAIT FOR RECEIVE OK
CLR   	RI
MOV    	A,SBUF
RET
;-------- Delay 50 usec-----------------------------------
;USE = R6,R7
DEL5m:	
;MOV	R7,#00h
;DEL5m1:
;MOV	R6,#0E4h
MOV	R6,#0Fh
DJNZ	R6,$
;DJNZ	R7,DEL5m1
RET
;----------delay 0.5 sec-----------------------------
;USE = R4,R5,R6,R7
DEL500m:
MOV	R4,#05h 
DEL500m1:
MOV	R5,#064h
DEL500m3:
MOV	R7,#03h
DEL500m2:
MOV	R6,#098h
DJNZ	R6,$
DJNZ	R7,DEL500m2
DJNZ       R5,DEL500m3
DJNZ	R4,DEL500m1
RET
;----------delay 0.1 sec-----------------------------
;USE = R4,R5,R6,R7
DEL100m:
;MOV	R4,#01h 
;DEL100m1:
MOV	R5,#032h
DEL100m3:
MOV	R7,#03h
DEL100m2:
MOV	R6,#098h
DJNZ	R6,$
DJNZ	R7,DEL100m2
DJNZ       R5,DEL100m3
;DJNZ	R4,DEL100m1
RET
;---------Hex to Dec------------------
;IN = DPTR		;FFFF
;OUT = R1,R2,R3		;R1=6  R2=55 R3=35
;REG = A,R1-R5,DPTR
HTOD:
CLR	A
MOV	R1,A
MOV	R2,A
MOV	R3,A
MOV	R4,#16
HTOD1:
MOV	A,DPL
RLC	A
MOV	DPL,A
MOV	A,DPH
RLC	A
MOV	DPH,A
MOV	R5,#3
MOV	R0,#3
HTOD2:
MOV	A,@R0
ADDC	A,ACC
DA	A
MOV	@R0,A
DEC	R0
DJNZ	R5,HTOD2
DJNZ	R4,HTOD1
RET
;********************************
SOUND_BEEP:
MOV	R1,#0Fh
DELS1:
MOV	R2,#8Fh
SOUND_BEEP1:  
CLR  	 ACC.6		         ;SOUND BIT = LOW
MOV	 DPTR,#DIGBL
MOVX   	@DPTR,A
ACALL  	 SOUND_BEEP2
  	           	              ;SOUND BIT = HIGH
SETB   	 ACC.6
MOV    	 DPTR,#DIGBL
MOVX   	@DPTR,A
ACALL   	 SOUND_BEEP2

DJNZ	R2,SOUND_BEEP1
DJNZ	R1,DELS1
			             ;back to main routine	
SOUND_BEEP2:
MOV	B,#6FH           
DJNZ	B,$
RET
;************************************************
SOUND_TRIG:
MOV	A,CONFIG
JB	ACC.0,SOUND_TRIG0	;If BEEP on Do next
CALL	DEL100m	;delay compensate trig loop
RET
SOUND_TRIG0:
MOV	 B,#30H                                     ;SOUND LOOP
SOUND_TRIG1:  
                                                                ;SOUND BIT = LOW
CLR    	 ACC.6
MOV	 DPTR,#DIGBL
MOVX   	@DPTR,A
CALL  	 SOUNDX
                                                	              ;SOUND BIT = HIGH
SETB   	 ACC.6
MOV    	 DPTR,#DIGBL
MOVX   	@DPTR,A
CALL   	 SOUNDX
DJNZ	 B,SOUND_TRIG1 	             ;NEXT LOOP
RET 			             ;back to main routine	
			  
SOUNDX: 
MOV	 A,#60H            ;DELAY
SOUNDX1:
DEC	 A
JNZ            SOUNDX1
RET
;****************************************
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

UDIV16:        mov     r7, #0          ; clear partial remainder
               mov     r6, #0
               mov     B, #16          ; set loop count

div_loop:      clr     C               ; clear carry flag
               mov     a, r0           ; shift the highest bit of
               rlc     a               ; the dividend into...
               mov     r0, a
               mov     a, r1
               rlc     a
               mov     r1, a
               mov     a, r6           ; ... the lowest bit of the
               rlc     a               ; partial remainder
               mov     r6, a
               mov     a, r7
               rlc     a
               mov     r7, a
               mov     a, r6           ; trial subtract divisor
               clr     C               ; from partial remainder
               subb    a, r2
               mov     dpl, a
               mov     a, r7
               subb    a, r3
               mov     dph, a
               cpl     C               ; complement external borrow
               jnc     div_1           ; update partial remainder if
                                       ; borrow
               mov     r7, dph         ; update partial remainder
               mov     r6, dpl
div_1:         mov     a, r4           ; shift result bit into partial
               rlc     a               ; quotient
               mov     r4, a
               mov     a, r5
               rlc     a
               mov     r5, a
               djnz    B, div_loop
               mov     a, r5           ; put quotient in r0, and r1
               mov     r1, a
               mov     a, r4
               mov     r0, a
               mov     a, r7           ; get remainder, saved before the
               mov     r3, a           ; last subtraction
               mov     a, r6
               mov     r2, a
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

UMUL16:        push    B
               push    dpl
               mov     a, r0
               mov     b, r2
               mul     ab              ; multiply XL x YL
               push    acc             ; stack result low byte
               push    b               ; stack result high byte
               mov     a, r0
               mov     b, r3
               mul     ab              ; multiply XL x YH
               pop     00H
               add     a, r0
               mov     r0, a
               clr     a
               addc    a, b
               mov     dpl, a
               mov     a, r2
               mov     b, r1
               mul     ab              ; multiply XH x YL
               add     a, r0
               mov     r0, a
               mov     a, dpl
               addc    a, b
               mov     dpl, a
               clr     a
               addc    a, #0
               push    acc             ; save intermediate carry
               mov     a, r3
               mov     b, r1
               mul     ab              ; multiply XH x YH
               add     a, dpl
               mov     r2, a
               pop     acc             ; retrieve carry
               addc    a, b
               mov     r3, a
               mov     r1, 00H
               pop     00H             ; retrieve result low byte
               pop     dpl
               pop     B
               ret


;====================================================================

CHKCAN:DB "0100",0Dh,00h		;PID send to check CAN connection
SERINIT1:DB "ATE0",0Dh,00h		;set Echo off
SERINIT2:DB "ATL0",0Dh,00h		;set Lind Feed off
SERINIT3:DB "ATH0",0Dh,00h		;set Msg Header  off
SERINIT4:DB "ATST01",0DH,00h	;set wait time = 4 msec
SERINIT5:DB "ATSPA6",0Dh,00h	;set Default CAN Bus and auto search
TITLE1:DB  00h,01h,02h," OBDII X-Meter v1",0Dh
TITLE2:DB  03h,04h,05h," ",07h,"az",06h,"a3 Zoom-Zoom",0Dh
TITLE3:DB  "By Jerry @ThaiMazda3",0Dh,00h

MENU1:DB "Select MENU Item [~]",0Dh,00h
MENU2:DB "Change Setting   [~]",0Dh,00h
VEHINFO:DB "Vehicle Information:",0Dh,00h
DTC:DB "[Number of DTC = --]",0Dh,16
MILON:DB "Warning! Service Req",0Dh,00h
DTCPID:DB "0101",0Dh,00h	;for SBLOCK
BEEP:DB "[ Set Sound ON/OFF ]",0Dh,00h
TOGGLE:DB "     Press to set[~]",0Dh,00h
SPDPID:DB "010D",0Dh,00h    ;for SBLOCK
MAFPID:DB "0110",0Dh,00h

CGM:DB 00h,00h,1Eh,15h,15h,15h,15h,00h,0Dh,00h	
CGD:DB 00h,00h,1Eh,11h,11h,11h,1Eh,00h,0Dh,00h	
;CG3:DB 00h,0Eh,01h,0Eh,01h,03h,1Eh,00h,0Dh,00h
CGUL:DB 00h,00h,01h,06h,08h,0Ch,1Bh,10h,0Dh,00h
CGUM:DB 00h,00h,1Fh,00h,00h,00h,11h,0Ah,0Dh,00h
CGUR:DB 00h,00h,10h,0Ch,02h,06h,1Bh,01h,0Dh,00h
CGLL:DB 10h,10h,08h,0Eh,03h,00h,00h,00h,0Dh,00h
CGLM:DB 04h,04h,00h,00h,11h,1Fh,00h,00h,0Dh,00h
CGLR:DB 01h,01h,02h,0Eh,18h,00h,00h,00h,0Dh,00h

PID04: DB "CAL Engine Load ---%",0Dh,16
PID05: DB "Coolant Temp: --- ",0DFh,"c",0Dh,14
PID06: DB "S-T Fuel Trim1 --- %",0Dh,15
PID07: DB "L-T Fuel Trim1 --- %",0Dh,15

PID0A: DB "Fuel Pressure ---kPa",0Dh,14
PID0B: DB "MAN Air Press ---kPa",0Dh,14
PID0C: DB "ENG Speed: ---- RPM ",0Dh,11
PID0D: DB "VEH Speed: --- km/h ",0Dh,11
PID0E: DB "IGN ADV Timing: ---",0DFh,0Dh,16
PID0F: DB "Intake Air Temp --",0DFh,"c",0Dh,15
PID10: DB "Air Flow ---.- g/sec",0Dh,9
PID11: DB "Throttle Pos: --- %  ",0Dh,14

PID2C: DB "Commanded EGR: --- %",0Dh,15
PID2D:DB "EGR Error: --- %    ",0Dh,11
PID2E:DB "CMD Evap Purge --- %",0Dh,15
PID2F: DB "Fuel Level: --- %   ",0Dh,12

PID33: DB "Baro Pressure ---kPa",0Dh,14

PID3C: DB "CAT 1 Temp: ---.- ",0DFh,"c",0Dh,12
PID3D: DB "CAT 2 Temp: ---.- ",0DFh,"c",0Dh,12

PID42: DB "PCM Voltage: --.-- V",0Dh,13
PID43: DB "ABS Engine Load ---%",0Dh,16
PID44: DB "CMD EQV Ratio: -.--   ",0Dh,15
PID45: DB "REL Throt Pos: --- %",0Dh,15
PID46: DB "AMB Air Temp: --- ",0DFh,"c",0Dh,14
NODATA: DB "                    ",0Dh,00
SPDMAF: DB "--- km/h,AF ---.-g/s",0Dh,00h
CONSUM: DB "Fuel Consmp --.-km/L",0Dh
END