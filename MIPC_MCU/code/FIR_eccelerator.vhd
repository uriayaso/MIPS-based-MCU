LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.aux_package.all;

entity FIR_eccelerator is
  generic (
    W : integer := 24;  -- data width
    M : integer := 8;   -- NUMBER OF PAST SAMPLES
    q : integer := 8    -- coefficient width
  );
  port (
    FIRCLK_i       : IN  std_logic;
    FIRRST_i       : IN  std_logic;
    FIRENA_i       : IN  std_logic;

    Xn_i           : IN  std_logic_vector(W-1 downto 0);
    COEF0_i        : IN  std_logic_vector(q-1 DOWNTO 0);
    COEF1_i        : IN  std_logic_vector(q-1 DOWNTO 0);
    COEF2_i        : IN  std_logic_vector(q-1 DOWNTO 0);
    COEF3_i        : IN  std_logic_vector(q-1 DOWNTO 0);
    COEF4_i        : IN  std_logic_vector(q-1 DOWNTO 0);
    COEF5_i        : IN  std_logic_vector(q-1 DOWNTO 0);
    COEF6_i        : IN  std_logic_vector(q-1 DOWNTO 0);
    COEF7_i        : IN  std_logic_vector(q-1 DOWNTO 0);

    Yn_o           : OUT std_logic_vector(W-1 downto 0);
    OUTPUT_valid   : OUT std_logic
  );
end FIR_eccelerator;

architecture dataflow of FIR_eccelerator is
  CONSTANT PROD_W : INTEGER := W + q;  -- product width
  CONSTANT SUM_W  : INTEGER := W + q;

  -- sample line
  subtype rowVector is std_logic_vector (W-1 DOWNTO 0);
  TYPE matrix IS ARRAY (0 TO M-1) OF rowVector;
  signal X : matrix := (others => (others => '0'));

  -- product results
  signal p0_w,p1_w,p2_w,p3_w,p4_w,p5_w,p6_w,p7_w : unsigned(PROD_W-1 DOWNTO 0);

  -- summation signals
  SIGNAL s0_w,s1_w,s2_w,s3_w,s01_w,s23_w,acc_w : unsigned(SUM_W-1 DOWNTO 0);

  -- output after dropping the q fraction bits
  SIGNAL y_no_reminder  : STD_LOGIC_VECTOR(W-1 DOWNTO 0);

  -- *** חדש: דחיית VALID בשני מחזורי FIRCLK ***
  signal valid_pipe : std_logic_vector(1 downto 0) := (others => '0');
begin
  -- shift register
  process (FIRCLK_i)
  begin
    if rising_edge(FIRCLK_i) then
      if FIRRST_i = '1' then
        X <= (others => (others => '0'));
      elsif FIRENA_i = '1' then
        X(0) <= Xn_i; -- current sample
        for i in 1 to M-1 loop
          X(i) <= X(i-1);
        end loop;
      end if;
    end if;
  end process;

  -- parallel multiplication
  p0_w <= (UNSIGNED(X(0)) * UNSIGNED(COEF0_i));
  p1_w <= (UNSIGNED(X(1)) * UNSIGNED(COEF1_i));
  p2_w <= (UNSIGNED(X(2)) * UNSIGNED(COEF2_i));
  p3_w <= (UNSIGNED(X(3)) * UNSIGNED(COEF3_i));
  p4_w <= (UNSIGNED(X(4)) * UNSIGNED(COEF4_i));
  p5_w <= (UNSIGNED(X(5)) * UNSIGNED(COEF5_i));
  p6_w <= (UNSIGNED(X(6)) * UNSIGNED(COEF6_i));
  p7_w <= (UNSIGNED(X(7)) * UNSIGNED(COEF7_i));

  -- summation tree
  s0_w  <= p0_w + p1_w;
  s1_w  <= p2_w + p3_w;
  s2_w  <= p4_w + p5_w;
  s3_w  <= p6_w + p7_w;
  s01_w <= s0_w + s1_w;
  s23_w <= s2_w + s3_w;
  acc_w <= s01_w + s23_w;  -- UQ((W+q).q)

  -- drop q fraction bits
  y_no_reminder <= std_logic_vector(acc_w(SUM_W-1 DOWNTO q));

  -- output & VALID generation (VALID נדחה ב-2 מחזורים)
  process (FIRRST_i, FIRCLK_i)
  begin
    if (FIRRST_i = '1') then
      Yn_o        <= (others => '0');
      OUTPUT_valid <= '0';
      valid_pipe  <= (others => '0');
    elsif rising_edge(FIRCLK_i) then
      -- רישום הדאטה רק כשהוכנסה דגימה (שומר על יציבות ביציאות)
      if FIRENA_i = '1' then
        Yn_o <= y_no_reminder;
      end if;

      -- דחיית ה-VALID בשני מחזורים: 00 -> 01 -> 11 (או 10 בהתאם לדפוס)
      valid_pipe  <= valid_pipe(0) & FIRENA_i;
      OUTPUT_valid <= valid_pipe(1);
    end if;
  end process;
  
end dataflow;
