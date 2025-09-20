.include "IO_map_addr.asm"
#--------------------------------------------------------------
#							 Global constants
#--------------------------------------------------------------
.eqv STACK_INIT_ADDR 		0x800
.eqv IDLE_STATE 			0
.eqv STATE0 				1
.eqv STATE1 				2
.eqv STATE2 				3

.eqv CLRKEY1IFG 			0xFFF7
.eqv CLRKEY2IFG 			0xFFEF
.eqv CLRKEY3IFG 			0xFFDF

.eqv FIFOFULL 				0x08
.eqv FIFOWEN 				0x20

.eqv BTHOLD_BTSSEL3_BTCLR 	0x3C
.eqv BTOUTEN_BTSSEL3 		0x58

.eqv BAUDRATE 				0x08
.eqv BAUDRATE_SWRST			0x09

.eqv FIFORST_FIRRST 		0x12
.eqv FIFOEMPTY				0x04		
.eqv FIRENA 				0x01
.eqv CLRFIRIFG				0xBF

.eqv IEALL 	  				0x7F			
#--------------------------------------------------------------
#							 Data Segment
#--------------------------------------------------------------
.data 
IV: .word main            	# Start of Interrupt Vector Table
	.word UartRX_ISR
	.word UartRX_ISR
	.word UartTX_ISR
	.word BT_ISR
	.word KEY1_ISR
	.word KEY2_ISR
	.word KEY3_ISR
	.word FIR_ISR
	.word FIR_ISR

state: 	.word 0				# contains the state of FSM based kernel 

UQ0_8coefs:	
	.byte 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20

UQ24_0xsamp:	
	.word 	0xa704f3,0xa34880,0x9fa59c,0x878246,0xe57b5c,
			0xf8db9c,0xd73fe1,0xe64f78,0xb5e517,0x89cf06,
			0x509fe1,0x381962,0x1d4048,0x3be3b0,0x115de7,
			0x21bc46,0x22d646,0x2d0d6f,0x295247,0x87cdc2

xSize: 		.word 20 		#  xSize = 20

UQ24_0y: 	.space 80		#  space = ySize_byte = xSize*4 = 80	 
#----------------------------------------------------------------  		 
#							Code Segment	
#----------------------------------------------------------------  		 
.text
main:	
	addi $sp,$zero,STACK_INIT_ADDR 			# $sp=0x800
	sw	 $0,state							# state = IDLE_STATE
	addi $t0,$zero,BTHOLD_BTSSEL3_BTCLR  
	sw   $t0,BTCTL       					# BTSSEL=3, BTHOLD=1, BTCLR=1, clear the rest rw bits
	sw   $0,IE        						# IE=0
	sw   $0,IFG        						# IFG=0
	addi $t0,$zero,0x0C35					# $t0=3125=0x0C35
	sw   $t0,BTCCR0							# BTCCR0=0x0C35
	srl	 $t0,$t0,1
	sw   $t0,BTCCR1							# BTCCR1=0x0C35/2, fpwm=MCLK/(8*3125) @DC=50%, fintBT=MCLK/(8*3125) 	
	addi $t0,$zero,BTOUTEN_BTSSEL3  
	sw   $t0,BTCTL       					# BTSSEL=3, BTOUTEN=1, clear the rest rw bits
	addi $t0,$zero,BAUDRATE_SWRST
	sw   $t0,UTCL       					# BAUDRATE=1 (115200 BR), SWRST=1, clear the rest rw bits		
	
	# Loading FIR coefficients
	la   $t2,UQ0_8coefs						# t2 points to UQ0_8coefs
	lw	 $t3,0($t2)							# $t3=UQ0_8coefs[3:0]
	sw 	 $t3,COEF3_0						# COEF3_0 = UQ0_8coefs[3:0]
	addi $t2,$t2,4
	lw	 $t3,0($t2)							# $t3=UQ0_8coefs[7:4]
	sw 	 $t3,COEF7_4						# COEF7_4 = UQ0_8coefs[7:4]
	
	# Filling up the FIR FIFO
	lw   $t6,xSize							# $t6 = xSamplesCnt (FIR use, $t6 has a global scope)
	add  $t7,$t6,$0							# $t7 = xSamplesCnt (FIFO use, $t7 has a global scope)
	addi $t0,$zero,FIFORST_FIRRST  
	sw   $t0,FIRCTL       					# FIFORST=1, FIRRST=1, clear the rest rw bits
	sw   $zero,FIRCTL       				# FIRCTL=0x00(FIFORST=0, FIRRST=0)
	la   $s0,UQ24_0xsamp					# $s0=xsampPtr, points to the array UQ24_0xsamp
	jal  fifo_fill
	
	# FIR start operation
	la   $t4,UQ24_0y						# t4 points to UQ24_0y, i.e. UQ24_0yPtr = t4
	addi $t0,$zero,FIRENA  
	sw   $t0,FIRCTL       					# FIRENA=1, clear the rest rw bits
	
	addi $t0,$zero,BAUDRATE
	sw   $t0,UTCL       					# BAUDRATE=1, SWRST=0, clear the rest rw bits
	
	addi $t0,$zero,IEALL  					
	sw   $t0,IE  							# set all seven IEs bits     			
	ori  $k0,$k0,0x01    					# EINT, $k0[0]=1 ($k0[0] uses as GIE)				
		
START_L:	
	lw   $gp,state							# interrupt driven changeable
	bne  $gp,$0,STATE0_L					# IDLE_STATE when $gp=0
	j    START_L

STATE0_L: 
	addi $t0,$zero,STATE0					 
	bne  $gp,$t0,STATE1_L					# check if $gp equals to STATE0
	addi $t8,$0,0							# $t8 is the global accumulated value
	addi $t9,$0,0x01						# $t9 is the global increment step value
	addi $t0,$0,IDLE_STATE					
	sw	 $t0,state							# set back to IDLE_STATE
	j    START_L
			
STATE1_L: 
	addi $t0,$zero,STATE1					
	bne  $gp,$t0,STATE2_L					# check if $gp equals to STATE1
	addi $t8,$0,0							# $t8 is the global accumulated value
	addi $t9,$0,0x10						# $t9 is the global increment step value
	addi $t0,$0,IDLE_STATE					
	sw	 $t0,state							# set back to IDLE_STATE
	j    START_L
	
STATE2_L: 
	addi $t0,$zero,STATE2					
	bne  $gp,$t0,START_L					# check if $gp equals to STATE2
	addi $t8,$0,0							# $t8 is the global accumulated value
	addi $t9,$0,0x100						# $t9 is the global increment step value
	addi $t0,$0,IDLE_STATE					
	sw	 $t0,state							# set back to IDLE_STATE
	j    START_L
		
KEY1_ISR:
	addi $t2,$zero,STATE0
	sw   $t2,state							# state=STATE0
		
	lw   $t1,IFG 							# read IFG
	andi $t1,$t1,CLRKEY1IFG 
	sw   $t1,IFG 							# clr KEY1IFG
	
	jr   $k1       							# reti
	
KEY2_ISR:
	addi $t2,$zero,STATE1
	sw   $t2,state							# state=STATE1
	
	lw   $t1,IFG  							# read IFG
	andi $t1,$t1,CLRKEY2IFG 
	sw   $t1,IFG  							# clr KEY2IFG
	
	jr   $k1        						# reti

KEY3_ISR:
	addi $t2,$zero,STATE2
	sw   $t2,state							# state=STATE2
	
	lw   $t1,IFG  							# read IFG
	andi $t1,$t1,CLRKEY3IFG 
	sw   $t1,IFG  							# clr KEY3IFG
	
	jr   $k1        						# reti
		
BT_ISR:	
	add  $t8,$t8,$t9  						# $t8,$t9 are global accumulated and step values
	andi $s1,$t8,0x0000000F
	sw   $s1,PORT_HEX0						# write to PORT_HEX0[7-0]
	andi $s1,$t8,0x000000F0
	srl  $s1,$s1,4
	sw   $s1,PORT_HEX1						# write to PORT_HEX1[7-0]
	andi $s1,$t8,0x00000F00
	srl  $s1,$s1,8
	sw   $s1,PORT_HEX2 						# write to PORT_HEX2[7-0]
	andi $s1,$t8,0x0000F000
	srl  $s1,$s1,16
	sw   $s1,PORT_HEX3 						# write to PORT_HEX3[7-0]
	andi $s1,$t8,0x000F0000
	srl  $s1,$s1,20
	sw   $s1,PORT_HEX4 						# write to PORT_HEX4[7-0]
	andi $s1,$t8,0x00F00000
	srl  $s1,$s1,24
	sw   $s1,PORT_HEX5 						# write to PORT_HEX5[7-0]
    jr   $k1        						# reti


FIR_ISR:
	lw   $t1,FIRCTL  						
	andi $t1,$t1,FIFOEMPTY 					# read FIFOEMPTY
	bne	 $zero,$t1,FIFO_L					# if(FIFOEMPTY == 0)
	lw 	 $t5,FIROUT							# $t5=FIROUT
	sw 	 $t5,0($t4)							# UQ24_0y[i]=FIROUT (i.e. *UQ24_0yPtr=FIROUT)
	addi $t4,$t4,4							# UQ24_0yPtr++
	addi $t6,$t6,-1							# ySamplesCounter--
	beq	 $t6,$zero,FIR_STOP
	j	 END
FIFO_L:
	jal  fifo_fill
	j	 END
FIR_STOP:
	lw   $t1,IE  							# read IE
	andi $t1,$t1,CLRFIRIFG 
	sw   $t1,IE  							# clr FIRIFG
	sw   $0,FIRCTL							# FIRCTL=0
END:	
	jr   $k1        						# reti
	    
UartRX_ISR:	
	lw   $t1,RXBF  							# read RXBUF
	sw   $t1,PORT_LEDR 						# write to PORT_LEDR[7-0]
    jr   $k1        						# reti

UartTX_ISR:	
	lw   $t0,PORT_SW  						# read the state of PORT_SW[7-0]
	sw   $t0,TXBF  							# write to TXBF
    jr   $k1        						# reti        
        
fifo_fill:
	beq  $t6,$0,end_fill					# if FIROUT was loaded xSize times then stop the FIFO filling 
	lw	 $t3,0($s0)							# $t3=UQ24_0xsamp[i]=*xsampPtr
	sw 	 $t3,FIRIN							# FIRIN=UQ24_0xsamp[i]
	addi $s0,$s0,4							# xsampPtr++
	addi $t7,$t7,-1							# xSamplesCnt--
	lw   $t0,FIRCTL  						# read FIRCTL
	ori  $t0,$t0,FIFOWEN 
	sw   $t0,FIRCTL  						# set FIFOWEN				
	lw   $t0,FIRCTL  			
	andi $t0,$t0,FIFOFULL 					# read FIFOFULL bit
	beq	 $0,$t0,fifo_fill					# while(FIFOFULL == 0)
end_fill:
	jr   $ra
