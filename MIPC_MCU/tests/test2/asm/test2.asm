.include "IO_map_addr.asm"
#--------------------------------------------------------------
#							 Global constants
#--------------------------------------------------------------
.eqv STACK_INIT_ADDR 			0x800
.eqv CLRKEY1IFG 				0xFFF7
.eqv CLRKEY2IFG 				0xFFEF
.eqv CLRKEY3IFG 				0xFFDF

.eqv BTHOLD_BTSSEL3_BTCLR 		0x3C
.eqv BTOUTEN_BTSSEL3 			0x58
.eqv BTOUTEN_BTSSEL2 			0x50
.eqv BTOUTEN_BTSSEL1 			0x48
.eqv BTOUTEN_BTSSEL0 			0x40

.eqv KEY3IE_KEY2IE_KEY1IE_BTIE 	0x3C
#--------------------------------------------------------------
#							 Data Segment
#--------------------------------------------------------------
.data 
IV: .word main            # Start of Interrupt Vector Table
	.word UartRX_ISR
	.word UartRX_ISR
	.word UartTX_ISR
	.word BT_ISR
	.word KEY1_ISR
	.word KEY2_ISR
	.word KEY3_ISR
	.word FIR_ISR
#--------------------------------------------------------------
#							 Code Segment
#--------------------------------------------------------------
.text
main:	
	addi $sp,$zero,STACK_INIT_ADDR 			# $sp=0x800
	add  $t3,$zero,$zero 					# $t3=0
	addi $t0,$zero,BTHOLD_BTSSEL3_BTCLR  
	sw   $t0,BTCTL       					# BTSSEL=3, BTHOLD=1, BTCLR=1, clear the rest bits
	sw   $0,IE        						# IE=0
	sw   $0,IFG        						# IFG=0
	addi $t0,$zero,0xC35					# $t0=3125=0xC35
	sw   $t0,BTCCR0							# BTCCR0=0xC35
	srl	 $t0,$t0,1
	sw   $t0,BTCCR1							# BTCCR1=0xC35 >> 1, fpwm=MCLK/(8*3125) with DC=50%, fint=MCLK/(8*3125) 	
	addi $t0,$zero,BTOUTEN_BTSSEL3  
	sw   $t0,BTCTL       					# BTSSEL=3, BTOUTEN=1, clear the rest
	addi $t0,$zero,KEY3IE_KEY2IE_KEY1IE_BTIE 
	sw   $t0,IE       						# KEY3IE=1, KEY2IE=1, KEY1IE=1, BTIE=1, clear the rest bits 
			
	ori  $k0,$k0,0x01     					# EINT, $k0[0]=1 ($k0[0] uses as GIE)
L:	j    L  	     						# infinite loop

	
KEY1_ISR:
	addi $t0,$zero,BTOUTEN_BTSSEL2  
	sw   $t0,BTCTL       					# BTSSEL=2, BTOUTEN=1, clear the rest, fpwm=fint=MCLK/(4*3125)
	
	lw   $t1,IFG 							# read IFG
	andi $t1,$t1,CLRKEY1IFG 
	sw   $t1,IFG 							# clr KEY1IFG
	jr   $k1       							# reti
	
KEY2_ISR:
	addi $t0,$zero,BTOUTEN_BTSSEL1  
	sw   $t0,BTCTL       					# BTSSEL=1, BTOUTEN=1, clear the rest, fpwm=fint=MCLK/(2*3125)
	
	lw   $t1,IFG  							# read IFG
	andi $t1,$t1,CLRKEY2IFG 
	sw   $t1,IFG  							# clr KEY2IFG
	jr   $k1        						# reti

KEY3_ISR:
	addi $t0,$zero,BTOUTEN_BTSSEL0  
	sw   $t0,BTCTL       					# BTSSEL=1, BTOUTEN=1, clear the rest, fpwm=fint=MCLK/3125
	
	lw   $t1,IFG  							# read IFG
	andi $t1,$t1,CLRKEY3IFG 
	sw   $t1,IFG  							# clr KEY3IFG
	jr   $k1        						# reti
		
BT_ISR:	
	addi $t3,$t3,1  						# $t3=$t3+1
	sw   $t3,PORT_LEDR 						# write to PORT_LEDR[7-0]
    jr   $k1        						# reti
        
FIR_ISR:	
	jr   $k1        						# reti
	
UartRX_ISR:	
	jr   $k1        						# reti            

UartTX_ISR:	
	jr   $k1        						# reti
	

         
