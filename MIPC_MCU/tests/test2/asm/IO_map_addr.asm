#--------------------------------------------------------------
#		    		MEMORY Mapped I/O addresses
#--------------------------------------------------------------
#define PORT_LEDR[7-0] 	0x800 - LSB byte address (Output Mode)
.eqv PORT_LEDR 0x800     # Define a constant named PORT_LEDR
#------------------- PORT_HEX0_HEX1 ---------------------------
#define PORT_HEX0[7-0] 	0x804 - LSB byte address (Output Mode)
#define PORT_HEX1[7-0] 	0x805 - LSB byte address (Output Mode)
.eqv PORT_HEX0 0x804     # Define a constant named PORT_HEX0
.eqv PORT_HEX1 0x805     # Define a constant named PORT_HEX1
#------------------- PORT_HEX2_HEX3 ---------------------------
#define PORT_HEX2[7-0] 	0x808 - LSB byte address (Output Mode)
#define PORT_HEX3[7-0] 	0x809 - LSB byte address (Output Mode)
.eqv PORT_HEX2 0x808     	# Define a constant named PORT_HEX2
.eqv PORT_HEX3 0x809     	# Define a constant named PORT_HEX3
#------------------- PORT_HEX4_HEX5 ---------------------------
#define PORT_HEX4[7-0] 	0x80C - LSB byte address (Output Mode)
#define PORT_HEX5[7-0] 	0x80D - LSB byte address (Output Mode)
.eqv PORT_HEX4 0x80C		# Define a constant named PORT_HEX4
.eqv PORT_HEX5 0x80D     	# Define a constant named PORT_HEX5
#--------------------------------------------------------------
#define PORT_SW[7-0] 	0x810 - LSB byte address (Input Mode)
.eqv PORT_SW 0x810			# Define a constant named PORT_SW
#--------------------------------------------------------------
#define PORT_KEY[3-1]  	0x814 - LSB nibble address (3 push-buttons - Input Mode)
.eqv PORT_KEY 0x814			# Define a constant named PORT_KEY
#--------------------------------------------------------------
#define UTCL           	0x818 - Byte address 
#define RXBF           	0x819 - Byte address 
#define TXBF           	0x81A - Byte address 
.eqv UTCL 0x818			# Define a constant named UTCL
.eqv RXBF 0x819			# Define a constant named RXBF
.eqv TXBF 0x81A			# Define a constant named TXBF
#--------------------------------------------------------------
#define BTCTL          	0x81C - LSB byte address 
#define BTCNT          	0x820 - Word address 
#define BTCCR0         	0x824 - Word address 
#define BTCCR1         	0x828 - Word address 
.eqv BTCTL 0x81C			# Define a constant named BTCTL
.eqv BTCNT 0x820			# Define a constant named BTCNT
.eqv BTCCR0 0x824			# Define a constant named BTCCR0
.eqv BTCCR1 0x828			# Define a constant named BTCCR1
#--------------------------------------------------------------
#define FIRCTL       	0x82C - Word address 
#define FIRIN        	0x830 - Word address 
#define FIROUT       	0x834 - Word address 
#define COEF3_0      	0x838 - Word address 
#define COEF7_4      	0x83C - Word address 
.eqv FIRCTL 0x82C			# Define a constant named FIRCTL
.eqv FIRIN 0x830			# Define a constant named FIRIN
.eqv FIROUT 0x834			# Define a constant named FIROUT
.eqv COEF3_0 0x838			# Define a constant named COEF3_0
.eqv COEF7_4 0x83C			# Define a constant named COEF7_4
#--------------------------------------------------------------
#define IE             	0x840 - LSB byte address 
#define IFG            	0x841 - LSB byte address 
#define TYPE           	0x842 - LSB byte address 
.eqv IE 0x840			# Define a constant named IE
.eqv IFG 0x841			# Define a constant named IFG
.eqv TYPE 0x842			# Define a constant named TYPE
#--------------------------------------------------------------



