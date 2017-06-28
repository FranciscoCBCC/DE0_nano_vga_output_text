library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity DE0_NANO is
    Port ( 
			CLOCK_50 	: in STD_LOGIC;
--//////////// LED //////////
			LED			: out STD_LOGIC_VECTOR(7 DOWNTO 0);
--
--//////////// KEY //////////
			KEY			: in STD_LOGIC_VECTOR(1 DOWNTO 0);
--
--//////////// SW //////////
			SW				: in STD_LOGIC_VECTOR(3 DOWNTO 0);
--
--//////////// SDRAM //////////
--			DRAM_ADDR	: out STD_LOGIC_VECTOR(12 DOWNTO 0);
--			DRAM_BA 		: out STD_LOGIC_VECTOR(1 DOWNTO 0);
--			DRAM_CAS_N 	: out STD_LOGIC;
--			DRAM_CKE 	: out STD_LOGIC;
--			DRAM_CLK 	: out STD_LOGIC;
--			DRAM_CS_N 	: out STD_LOGIC;
--			DRAM_DQ 		:  buffer STD_LOGIC_VECTOR(15 downto 0);
--			DRAM_DQM 	: out STD_LOGIC;
--			DRAM_RAS_N 	: out STD_LOGIC;
--			DRAM_WE_N 	: out STD_LOGIC;
--
--//////////// EPCS //////////
			EPCS_ASDO 	: out STD_LOGIC;
			EPCS_DATA0 	: in STD_LOGIC;
			EPCS_DCLK 	: out STD_LOGIC;
			EPCS_NCSO 	: out STD_LOGIC;
--
--//////////// Accelerometer and EEPROM //////////
			G_SENSOR_CS_N : out STD_LOGIC;
			G_SENSOR_INT : in STD_LOGIC;
			I2C_SCLK 	: out STD_LOGIC;
			I2C_SDAT 	: buffer STD_LOGIC;
--
--//////////// ADC //////////
			ADC_CS_N 	: out STD_LOGIC;
			ADC_SADDR 	: out STD_LOGIC;
			ADC_SCLK 	: out STD_LOGIC;
			ADC_SDAT 	: in STD_LOGIC;
			
--//////////// GPIO //////////
			GPIO_2 		: buffer STD_LOGIC_VECTOR(12 DOWNTO 0);
			GPIO_2_IN 	: in STD_LOGIC_VECTOR(2 DOWNTO 0);

			GPIO_0_D		: buffer STD_LOGIC_VECTOR(33 DOWNTO 0);
			GPIO_0_IN 	: in STD_LOGIC_VECTOR(1 DOWNTO 0);
			
			GPIO_1_D		: out STD_LOGIC_VECTOR(33 DOWNTO 0);	  
			GPIO_1_IN 	: in STD_LOGIC_VECTOR(1 DOWNTO 0)
											);
end DE0_NANO;

architecture Behavioral of DE0_NANO is

			--Sync Signals
SIGNAL 	h_sync, v_sync	:	STD_LOGIC;
			--Video Enables
SIGNAL 	video_en, 
			horizontal_en, 
			vertical_en	: STD_LOGIC;
			--Color Signals
SIGNAL	red_signal,
			green_signal,
			blue_signal	: STD_LOGIC;
			--Sync Counters
SIGNAL 	h_cnt, 
			v_cnt : STD_LOGIC_VECTOR(10 DOWNTO 0);
			
SIGNAL	color_en : STD_LOGIC_VECTOR(2 DOWNTO 0);	
			--color_en (0) enabled RED
			--color_en (0) enabled GREEN
			--color_en (0) enabled BLUE

begin

video_en <= horizontal_en AND vertical_en;		
		
process
variable cnt: integer range 0 to 50000000;
variable color_cnt: integer range 0 to 16;
begin

	WAIT UNTIL(CLOCK_50'EVENT) AND (CLOCK_50 = '1');
	
	IF(cnt = 50000000)THEN		
	cnt := 0;
	ELSE
	cnt := cnt  + 1;
	END IF;

	--Increment Color Count Ever 0.5 Seconds
	IF(cnt = 0)THEN
		color_cnt := color_cnt + 1;
	--ELSIF(cnt = 25000000)THEN		
	--	color_cnt := color_cnt + 1;
	END IF;	

	
	CASE color_cnt IS
		when 0 =>	--WHITE
					color_en <= "111";
		when 1 =>	--RED
					color_en <= "001";
		when 2 =>	--YELLOW
					color_en <= "011";		
		when 3 =>	--GREEN
					color_en <= "010";		
		when 4 =>	--TEAL
					color_en <= "110";		
		when 5 =>	--BLUE
					color_en <= "100";		
		when 6 =>	--VIOLET
					color_en <= "101";		
		when 7 =>	--BLACK
					color_en <= "000";	
		when others =>	
					color_cnt := 0;
	END CASE;
	
		--Generate Horizontal Data
				--160 Rows Of Red
	IF (v_cnt >= 0) AND  (v_cnt <= 799) THEN
		red_signal <= color_en(0);
		green_signal <= color_en(1);
		blue_signal <= color_en(2);			
	END IF;
	
	--Horizontal Sync
		
			--Generate Horizontal Sync
		IF (h_cnt <= 975) AND (h_cnt >= 855) THEN
			h_sync <= '0';
		ELSE
			h_sync <= '1';
		END IF;
		
			--Reset Horizontal Counter
		IF (h_cnt = 1039) THEN
			h_cnt <= "00000000000";
		ELSE
			h_cnt <= h_cnt + 1;
		END IF;			
	
	--Vertical Sync
		--Reset Vertical Counter
		IF (v_cnt >= 665) AND (h_cnt >= 1039) THEN
			v_cnt <= "00000000000";
		ELSIF (h_cnt = 1039) THEN
			v_cnt <= v_cnt + 1;
		END IF;
		
			--Generate Vertical Sync
		IF (v_cnt <= 642) AND (v_cnt >= 636) THEN
			v_sync <= '0';	
		ELSE
			v_sync <= '1';
		END IF;
	
		--Generate Horizontal Data
	IF (h_cnt <= 799) THEN
		horizontal_en <= '1';
	ELSE
		horizontal_en <= '0';
	END IF;
	
		--Generate Vertical Data
	IF (v_cnt <= 599) THEN
		vertical_en <= '1';
	ELSE
		vertical_en <= '0';
	END IF;
	
	--Assign Physical Signals To VGA
	--red		<= red_signal AND video_en;
	GPIO_1_D(1)	<= red_signal AND video_en;
	--green   <= green_signal AND video_en;
	GPIO_1_D(3)	<= green_signal AND video_en;
	--blue	<= blue_signal AND video_en;
	GPIO_1_D(5)	<= blue_signal AND video_en;
	
	--hsync	<= h_sync;
	GPIO_1_D(7) <= h_sync;
	--vsync	<= v_sync;		
	GPIO_1_D(9) <= v_sync;	
end process;
				
end Behavioral;
