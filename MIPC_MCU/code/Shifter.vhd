LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE work.const_package.all;
----------------------------
------entity definition-----
----------------------------
entity Shifter IS
  GENERIC (n : INTEGER := 32;
		   k : integer := 5);   -- k=log2(n)
	
	PORT (
	X,Y 	:IN std_logic_vector (n-1 DOWNTO 0);
	dir		:IN std_logic_vector (2 DOWNTO 0);
	res		:OUT std_logic_vector (n-1 DOWNTO 0)
	);
end Shifter;

------------------------------------------
----------ARCHITECTURE DEFINITION---------
------------------------------------------
architecture Shift OF Shifter IS
	subtype rowVector is std_logic_vector (n-1 DOWNTO 0);
	TYPE matrix IS ARRAY (0 TO k) OF rowVector;
	SIGNAL shiftMat : matrix;
	SIGNAL zeros : std_logic_vector (n-1 downto 0) := (others => '0');
	SIGNAL shf_sel : std_logic_vector (k-1 downto 0); 
	constant zer_c : std_logic_vector (n-2 downto 0) := (others => '0');
	begin
	
	-------- initialize shf_sel and the first row with my input-----------
	shf_sel <= x( k-1 downto 0);
	shiftMat(0) <= y when (dir = "000" or dir = "001") else zeros;
	
	shiftLoop: for i in 0 to k-1 generate	
		constant shiftAmount : INTEGER := 2**i;
		begin	
			shiftMat(i+1) <=
				------shift left--------
				shiftMat(i)(n-1-shiftAmount downto 0) & zeros (shiftAmount-1 downto 0) when (shf_sel(i) = '1' and dir = "000") else 
				------shift right-------
				zeros (shiftAmount-1 downto 0) & shiftMat(i)(n-1 downto shiftAmount)  when (shf_sel(i) = '1' and dir = "001") else 
				------no shift----------
				shiftMat(i);
				
		end generate shiftLoop;
		
		
	res <= shiftMat(k);--final result
end Shift;
	