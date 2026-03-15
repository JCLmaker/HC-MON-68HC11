; Ein Test für eine VT100 Emulation 80x24 Bildschirm
; Berlin, 06.02.2026, ursprünglich auch des 90er Jahren

	ORG	$6000		;RAM beginnt bei $6000

	INCLUDE	EQUS.INC
	INCLUDE VT100.INC

*** HAUPTPROGRAMM ***

	LDS	#$7000		;Stack ab $7000
	LDAA	#1
	STAA	XPOS		;POSITIONSZAEHLER LOESCHEN
	STAA	YPOS
	CLS			;BILDSCHIRM LOESCHEN
;	SWI			;Breakpoint
INPUT:	JSR	TERINP		;warten Eingabe auf dem Terminal
	CMPA	#$1B		;ESC-Zeichen -> evt. Cursor-Taste, also weiter zu Auswertung
	BEQ	WEITER		
	JMP	ZEICHEN
WEITER:	JSR	TERINP		;nächstes Zeichen nach ESC
	CMPA	#$5B		;"["-Zeichen
	BNE	INPUT		;nein, also wieder zur Eingabe auf dem Terminal
	JSR	TERINP		;nächsten Zeichen holen
	CMPA	#$41		;"A" ? -> also Pfeil-Taste oben
	BEQ	OBEN
	CMPA	#$42		;"B" ? -> also Pfeil-Taste unten
	BEQ	UNTEN
	CMPA	#$43		;"C" ? -> also Pfeil-Taste rechts
	BEQ	RECHTS
	CMPA	#$44		;"D" ? -> also Pfeil-Taste links
	BEQ	LINKS	
	JMP	INPUT


OBEN	LDAA	YPOS
	BEQ	INPUT		;oberste Zeile angekommen?
	DECA
	STAA	YPOS
	LDAB	XPOS
	LDX	#?TEXT
	JSR	PRINT		;Sequenz für Pfeil nach oben ausgeben, Positionen in A und B
	JMP	INPUT		;weiter auf neues Zeichen warten
?TEXT	DB	$1B,'[','1','A',0
UNTEN	LDAA	YPOS
	CMPA	#24
	BEQ	INPUT
	INCA
	STAA	YPOS
	LDAB	XPOS
	LDX	#?TEXT
	JSR	PRINT
	JMP	INPUT
?TEXT	DB	$1B,'[','1','B',0
RECHTS	LDAB	XPOS
	CMPB	#80
	BEQ	INPUT
	INCB
	STAB	XPOS
	LDAA	YPOS
	LDX	#?TEXT
	JSR	PRINT
	BRA	INPUT
?TEXT	DB	$1B,'[','1','C',0
LINKS	LDAB	XPOS
	BEQ	INPUT
	DECB
	STAB	XPOS
	LDAA	YPOS
	LDX	#?TEXT
	JSR	PRINT
	JMP	INPUT
?TEXT	DB	$1B,'[','1','D',0

ZEICHEN	CMPA	#$20		;Leerzeichen
	BPL	?W1		;ja, es war mehr als ein Leerzeichen
	JMP	INPUT	
?W1	CMPA	#$7B		;max. bis 7B, dann war ein Zeichen das ausgegeben werden kann
	BMI	?W2
	JMP	INPUT
?W2	;LDX	#SETPOS		;x und y Position vor Ausgabe setzten
	;JSR	PRINT
	JSR	TEROUT		;jetzt wir das ASCII-Zeichen ausgeben (Bereich von $21 bis $7A)
	LDAB	XPOS		;X-Position anpassen bis max. Spalte 80
	CMPB	#80
	BEQ	?W3
	INCB
	STAB	XPOS
?W3	JMP	INPUT		

SETPOS	DB	$1B		;Sequenz für VT100
	DB	'['
YPOS	DS	1		;Speicher für Y-Position
	DB	';'
XPOS	DS	1		;Speicher für X-Position
	DB	'H'
	DB	0

	END

