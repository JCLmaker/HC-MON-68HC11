;modifiziert 07.02.2026

	;UHR-ROUTINE FUER 68HC11
	;8 MHZ
	;BETRIEBSSYSTEM BEI $E000
	;AUSGABE AUF SERIELLE VT100


	INCLUDE MAP_HC11.INS

TIME    EQU     $6000
ESC     EQU     $1B

COLD	EQU	$E000
WARM	EQU	$E003
TERINP	EQU	$E006
TEROUT	EQU	$E009
TERIO	EQU	$E00C
PRINT	EQU	$E00F
PRCRLF	EQU	$E012
PRSPAC	EQU	$E015
INPHEX	EQU	$E018
OUTHEX	EQU	$E01B
INPWOR	EQU	$E01E
OUTWOR	EQU	$E021
QINPUT	EQU	$E024
DASMXB	EQU	$E027
DISMON	EQU	$E02A
ENAMON	EQU	$E02D

JSPI    EQU     $9F7C
JPAIE   EQU     $9F7F
JPAO    EQU     $9F82
JTOF    EQU     $9F85
JTOC5   EQU     $9F88
JTOC4   EQU     $9F8B
JTOC3   EQU     $9F8E
JTOC2   EQU     $9F91
JTOC1   EQU     $9F94
JTIC3   EQU     $9F97
JTIC2   EQU     $9F9A
JTIC1   EQU     $9F9D
JRTI    EQU     $9FA0
JIRQ    EQU     $9FA3
JXIRQ   EQU     $9FA6

	.ORG    $6000

START   LDS     #$7000          ;Stack ab $7000
	
	LDX     #TIMEIRQ        ;IRQ-Vektor umlenken
	STX     JTOC5+1

	LDAA    #$00            ;Speicher fuer Stunde, Minute, Sekunde
	STAA    $FF		;Sekunde
	STAA    $FE		;Minute
	STAA    $FD		;Stunde

	LDX     #TEXT3
	JSR     PRINT
	LDX     #TEXT4
	JSR     PRINT


;Timer-IRQ setzen
;hier stimmt noch etwas nicht?

;       SWI

	LDD     TCNT
	ADDD    #TIME
	STD     TOC5
	LDAA    TMSK1
	ORAA    #%00001000
	STAA    TMSK1
	CLI
	
	LDX	#CLS		;gesamten Bildschirm löschen
	JSR	PRINT

	JSR	PRCRLF		;nächste Zeile

	LDX     #79             ;80-mal "-" ausgeben
HEINZ   LDAA    #$2D
	JSR     TEROUT
	DEX
	BNE     HEINZ

	JSR	PRCRLF		;Abfrage und Eingabe der Stunde
	JSR	PRCRLF
	LDX	#STUNDE
	JSR	PRINT
	JSR	INPHEX
	STAA	$FD

	JSR	PRCRLF		;Abfrage und Eingabe der Minute
	JSR	PRCRLF
	LDX	#MINUTE
	JSR	PRINT
	JSR	INPHEX
	STAA	$FE


	JSR	PRCRLF		;Abfrage und Eingabe der Sekunde
	JSR	PRCRLF
	LDX	#SEKUNDE
	JSR	PRINT
	JSR	INPHEX
	STAA	$FF
	
	SWI

	.ORG    $6100

TIMEIRQ LDAA    #%00001000
	STAA    TFLG1
	LDD     TCNT
	ADDD    #TIME
	STD     TOC5
	LDAA    $FC
	BEQ     AUSGAB
	DECA
	STAA    $FC     
	RTI

AUSGAB  LDAA    #ESC
	JSR     TEROUT
	LDAA    #$37
	JSR     TEROUT
	LDX     #TEXT1
	JSR     PRINT
	LDX     #TEXT2
	JSR     PRINT

	LDAB    #$59
	CMPB    $FF
	BNE     LOOP1
	LDAA    #0
	STAA    $00FF
	CMPB    $FE
	BNE     LOOP2
	LDAA    #0
	STAA    $00FE
	LDAB    #$23
	CMPB    $FD
	BNE     LOOP3
	LDAA    #0
	STAA    $00FD

AUFI    LDAA    $FD
	JSR     OUTHEX
	LDAA    #$3A
	JSR     TEROUT
	LDAA    $FE
	JSR     OUTHEX
	LDAA    #$3A
	JSR     TEROUT
	LDAA    $FF
	JSR     OUTHEX
	LDAA    #$63
	STAA    $FC
	LDAA    #ESC
	JSR     TEROUT
	LDAA    #$38
	JSR     TEROUT
	RTI

LOOP1   LDAA    $FF
	ADDA    #1
	DAA
	STAA    $FF
	BRA     AUFI

LOOP2   LDAA    $FE
	ADDA    #1
	DAA
	STAA    $FE
	BRA     AUFI

LOOP3   LDAA    $FD
	ADDA    #1
	DAA
	STAA    $FD
	BRA     AUFI

	DB      'X'
TEXT1   DB      $1B,$5B,$30,$31,$3B,$33,$33,$48,$00     ;;set cursor position y=01 x=33
	DB      'X'
TEXT2   DB      $1B,$23,$36,$00                         ;Fettschrift ein
	DB      'X'
TEXT3   DB      $1B,$5B,$30,$33,$3B,$32,$34,$72,$00     ;set scrolling region oben=03 unten=24
	DB      'X'
TEXT4   DB      $1B,$5B,$30,$32,$3B,$30,$31,$48,$00     ;set cursor position y=02 x=01

CLS	DB	$1B,$5B,$32,$4A,$1B,$5B,$48,$00		;gesamten Bildschirm löschen

STUNDE	DB	'Stunde: ',0
MINUTE	DB	'Minute: ',0
SEKUNDE	DB	'Sekunde: ',0

	.END
