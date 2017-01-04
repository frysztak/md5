----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:51:19 12/14/2016 
-- Design Name: 
-- Module Name:    MD5 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MD5 is
    Port ( data_in:     in  STD_LOGIC_VECTOR (31 downto 0);
           data_out:    out STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
           req_data:    out STD_LOGIC := '0';
           done:        out STD_LOGIC := '0';
           err:         out STD_LOGIC := '0';
           start:       in  STD_LOGIC;
           clk:         in  STD_LOGIC;
           reset:       in  STD_LOGIC);
end MD5;

architecture Behavioral of MD5 is
subtype uint512_t is unsigned(0 to 511);
subtype uint32_t is unsigned(31 downto 0);
subtype uint8_t is unsigned(7 downto 0);

type const_s is array (0 to 63) of uint8_t;
type const_k is array (0 to 63) of uint32_t;
type message is array (0 to 15) of uint32_t;

constant S: const_s := (X"07", X"0C", X"11", X"16", -- 7, 12, 17, 22,
                        X"07", X"0C", X"11", X"16", -- 7, 12, 17, 22,
                        X"07", X"0C", X"11", X"16", -- 7, 12, 17, 22,
                        X"07", X"0C", X"11", X"16", -- 7, 12, 17, 22,

						X"05", X"09", X"0E", X"14", -- 5,  9, 14, 20,
						X"05", X"09", X"0E", X"14", -- 5,  9, 14, 20,
						X"05", X"09", X"0E", X"14", -- 5,  9, 14, 20,
						X"05", X"09", X"0E", X"14", -- 5,  9, 14, 20,

						X"04", X"0B", X"10", X"17", -- 4, 11, 16, 23,
						X"04", X"0B", X"10", X"17", -- 4, 11, 16, 23,
						X"04", X"0B", X"10", X"17", -- 4, 11, 16, 23,
						X"04", X"0B", X"10", X"17", -- 4, 11, 16, 23,

						X"06", X"0A", X"0F", X"15", -- 6, 10, 15, 21);
						X"06", X"0A", X"0F", X"15", -- 6, 10, 15, 21);
						X"06", X"0A", X"0F", X"15", -- 6, 10, 15, 21);
						X"06", X"0A", X"0F", X"15"); -- 6, 10, 15, 21);
										
constant K: const_k := (X"d76aa478", X"e8c7b756", X"242070db", X"c1bdceee",
						X"f57c0faf", X"4787c62a", X"a8304613", X"fd469501",
						X"698098d8", X"8b44f7af", X"ffff5bb1", X"895cd7be",
						X"6b901122", X"fd987193", X"a679438e", X"49b40821",
						X"f61e2562", X"c040b340", X"265e5a51", X"e9b6c7aa",
						X"d62f105d", X"02441453", X"d8a1e681", X"e7d3fbc8",
						X"21e1cde6", X"c33707d6", X"f4d50d87", X"455a14ed",
						X"a9e3e905", X"fcefa3f8", X"676f02d9", X"8d2a4c8a",
						X"fffa3942", X"8771f681", X"6d9d6122", X"fde5380c",
						X"a4beea44", X"4bdecfa9", X"f6bb4b60", X"bebfbc70",
						X"289b7ec6", X"eaa127fa", X"d4ef3085", X"04881d05",
						X"d9d4d039", X"e6db99e5", X"1fa27cf8", X"c4ac5665",
						X"f4292244", X"432aff97", X"ab9423a7", X"fc93a039",
						X"655b59c3", X"8f0ccc92", X"ffeff47d", X"85845dd1",
						X"6fa87e4f", X"fe2ce6e0", X"a3014314", X"4e0811a1",
						X"f7537e82", X"bd3af235", X"2ad7d2bb", X"eb86d391");

signal M : uint512_t := (others => '0');
signal message_length : uint32_t := (others => '0');
signal data_counter : natural := 0;
signal out_counter  : natural := 0;
signal loop_counter, loop_counter_n : natural := 0;

constant a0 : uint32_t := X"67452301";
constant b0 : uint32_t := X"efcdab89";
constant c0 : uint32_t := X"98badcfe";
constant d0 : uint32_t := X"10325476";

signal A, A_n : uint32_t := a0;
signal B, B_n : uint32_t := b0;
signal C, C_n : uint32_t := c0;
signal D, D_n : uint32_t := d0;
signal F      : uint32_t := to_unsigned(0, A'length);
signal g      : integer := 0;

type state_t is (idle,
                 load_length,
                 load_data, 
                 pad,
                 rotate,
                 stage1_F, stage1_B, 
                 stage2_F, stage2_B,
                 stage3_F, stage3_B,
                 stage4_F, stage4_B,
                 stage5, -- add a0 to A, b0 to B etc.
                 stage6, -- swap endianness
                 finished,
                 store_data);
signal state, state_n : state_t;

function leftrotate(x: in uint32_t; c: in uint8_t) return uint32_t is
begin
	return SHIFT_LEFT(x, to_integer(c)) or SHIFT_RIGHT(x, to_integer(32-c));
end function leftrotate;

function swap_endianness(x: in uint32_t) return uint32_t is
begin
    return x(7 downto 0) & 
           x(15 downto 8) &
           x(23 downto 16) &
           x(31 downto 24);
end function swap_endianness;

begin
    main: process(reset, clk)
    begin
        if (reset = '1') then
            state <= idle;
            loop_counter <= 0;
        elsif (clk'event and clk = '1') then
            state <= state_n;
            loop_counter <= loop_counter_n;
            A <= A_n;
            B <= B_n;
            C <= C_n;
            D <= D_n;
        end if;
    end process main;

    fsm: process(state, start, loop_counter, data_counter, out_counter)
    begin
        state_n <= state;

        case state is
            when idle =>
                if (start = '1') then
                    state_n <= load_length;
                end if;

            when load_length =>
                state_n <= load_data;

            when load_data => 
                if (data_counter >= message_length) then
                    state_n <= pad;
                end if;

            when pad =>
                state_n <= rotate;

            when rotate =>
                state_n <= stage1_F;

            when stage1_F =>
                state_n <= stage1_B;

            when stage1_B =>
                if (loop_counter = 15) then
                    state_n <= stage2_F;
                else
                    state_n <= stage1_F;
                end if;

            when stage2_F =>
                state_n <= stage2_B;

            when stage2_B =>
                if (loop_counter = 31) then
                    state_n <= stage3_F;
                else
                    state_n <= stage2_F;
                end if;

            when stage3_F =>
                state_n <= stage3_B;

            when stage3_B =>
                if (loop_counter = 47) then
                    state_n <= stage4_F;
                else
                    state_n <= stage3_F;
                end if;

            when stage4_F =>
                state_n <= stage4_B;

            when stage4_B =>
                if (loop_counter = 63) then
                    state_n <= stage5;
                else
                    state_n <= stage4_F;
                end if;

            when stage5 =>
                state_n <= stage6;

            when stage6 =>
                state_n <= finished;

            when finished =>
                if (start = '1') then
                    state_n <= store_data;
                end if;

            when store_data =>
                if (out_counter = 4) then
                    state_n <= idle;
                end if;

            when others => null;
        end case;
    end process fsm;

    calc: process(reset, clk, state, data_counter, loop_counter)
        variable tmp : uint32_t;
    begin
        if (reset = '0' and clk'event and clk = '1') then

            case state is
                when load_length =>
                    message_length <= unsigned(data_in);

                when load_data =>
                    M(data_counter to data_counter+31) <= unsigned(data_in);
                    if (data_counter >= message_length) then
                        req_data <= '0';
                    else
                        data_counter <= data_counter + 32;
                    end if;

                when pad =>
                    M(to_integer(message_length)) <= '1';
                    M(to_integer(message_length+1) to 447) <= (others => '0');
                    M(448 to 511) <= 
                    swap_endianness(message_length) & "00000000000000000000000000000000";

                when rotate => 
                    for i in 0 to 15 loop
                        M(32*i to 32*i+31) <= swap_endianness(M(32*i to 32*i+31));
                    end loop;

                when stage1_B | stage2_B | stage3_B | stage4_B =>
                    A_n <= D;
                    B_n <= B + leftrotate(A + F + K(loop_counter) + M(g to g+31), s(loop_counter)); 
                    C_n <= B;
                    D_n <= C;
                    loop_counter_n <= loop_counter + 1;

                when stage1_F =>
                    F <= (B_n and C_n) or (not B_n and D_n);
                    g <= 32*loop_counter_n;

                when stage2_F =>
                    F <= (D_n and B_n) or (not D_n and C_n);
                    g <= 32*((5*loop_counter_n + 1) mod 16);

                when stage3_F =>
                    F <= B_n xor C_n xor D_n;
                    g <= 32*((3*loop_counter_n + 5) mod 16);

                when stage4_F =>
                    F <= C_n xor (B_n or not D_n);
                    g <= 32*((7*loop_counter_n) mod 16);

                when stage5 =>
                    A_n <= A_n + a0;
                    B_n <= B_n + b0;
                    C_n <= C_n + c0;
                    D_n <= D_n + d0;

                when stage6 =>
                    A_n <= swap_endianness(A_n);
                    B_n <= swap_endianness(B_n);
                    C_n <= swap_endianness(C_n);
                    D_n <= swap_endianness(D_n);

                when finished =>
                    done <= '1';

                when store_data =>
                    case out_counter is
                        when 0 => data_out <= std_logic_vector(A);
                        when 1 => data_out <= std_logic_vector(B);
                        when 2 => data_out <= std_logic_vector(C);
                        when 3 => data_out <= std_logic_vector(D);
                        when others => null;
                    end case;
                    out_counter <= out_counter + 1;
                    done <= '0';

                when others => null;
            end case;
            
        end if;
    end process calc;

end Behavioral;

