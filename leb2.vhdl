-- #############################################################################
-- #
-- #    VHDL Tutorial Summary from Lab 2: Introduction to VHDL
[cite_start]-- #    Course: CMPN301: Computer Architecture [cite: 3]
[cite_start]-- #    Institution: Cairo University, Faculty of Engineering [cite: 4, 5]
-- #
-- #    This file demonstrates key VHDL concepts for beginners, including:
-- #    1. Entity and Architecture basics.
-- #    2. Concurrent conditional statements (`WHEN...ELSE`, `WITH...SELECT`).
[cite_start]-- #    3. The danger of creating unintended latches. [cite: 97]
[cite_start]-- #    4. The utility of the "OTHERS" keyword. [cite: 114]
[cite_start]-- #    5. Creating scalable designs with GENERIC and FOR...GENERATE. [cite: 23, 24]
-- #
-- #############################################################################


-- ============================================================================
-- Concept 1: The 4-to-1 Multiplexer (Mux)
[cite_start]-- A Mux selects one of four inputs based on a 2-bit selection signal. [cite: 28]
-- ============================================================================

[cite_start]-- The ENTITY is the "black box" view, defining only the inputs and outputs (PORTs). [cite: 8]
ENTITY mux IS
    PORT(
        [cite_start]in0, in1, in2, in3 : IN  std_logic;                      -- Four 1-bit data inputs [cite: 32]
        sel               : IN  std_logic_vector(1 DOWNTO 0);   [cite_start]-- One 2-bit select line [cite: 38]
        [cite_start]out1              : OUT std_logic                       -- One 1-bit output [cite: 41]
    );
END ENTITY mux;

[cite_start]-- The ARCHITECTURE describes the internal logic of the entity. [cite: 9]
[cite_start]-- All statements in an architecture are CONCURRENT, not sequential. [cite: 11]

-- Architecture Example 'a_mux' using "WHEN...ELSE"
[cite_start]-- This creates a priority-based assignment. [cite: 46]
ARCHITECTURE a_mux OF mux IS
BEGIN
    out1 <= in0 WHEN sel = "00" ELSE
            in1 WHEN sel = "01" ELSE
            in2 WHEN sel = "10" ELSE
            in3; [cite_start]-- The final ELSE handles all other cases, preventing a latch. [cite: 48, 49]
END ARCHITECTURE a_mux;

-- Architecture Example 'b_mux' using "WITH...SELECT"
[cite_start]-- This is often a cleaner way to describe a mux without priority. [cite: 46]
ARCHITECTURE b_mux OF mux IS
BEGIN
    WITH sel SELECT
        [cite_start]out1 <= in0 WHEN "00", [cite: 53]
                [cite_start]in1 WHEN "01", [cite: 54]
                [cite_start]in2 WHEN "10", [cite: 55]
                [cite_start]in3 WHEN "11"; [cite: 56]
END ARCHITECTURE b_mux;

-- NOTE on Latches: If you miss a case in a conditional assignment (e.g., you don't specify
-- what happens when sel="11"), the synthesizer will infer a LATCH to hold the previous
[cite_start]-- value. [cite: 97] [cite_start]This is usually undesirable in combinational logic. [cite: 97]


-- ============================================================================
-- Concept 2: The "OTHERS" Keyword
[cite_start]-- A very useful shortcut for working with vectors (buses). [cite: 113, 121, 132]
-- ============================================================================

-- Example Usage (not a real entity, just for demonstration)
-- SIGNAL F : std_logic_vector(31 DOWNTO 0);

-- 1. To set all bits of a vector to the same value:
-- F <= (OTHERS => '0'); [cite_start]-- Assigns '0' to all 32 bits of F. [cite: 117]

-- 2. To set a specific bit and assign others a default value:
-- F <= (7 => '1', OTHERS => '0'); [cite_start]-- Sets bit 7 to '1' and all other bits to '0'. [cite: 127]

-- 3. To provide a default case in a WITH...SELECT statement to avoid latches:
-- WITH S SELECT
[cite_start]--     F_out <= a WHEN "0010", [cite: 139]
[cite_start]--              b WHEN OTHERS; [cite: 140] -- 'b' is assigned for all other values of S.


-- ============================================================================
-- Concept 3: Building a Scalable N-Bit Adder
-- We start with a 1-bit block and use it to build a generic N-bit adder.
-- ============================================================================

[cite_start]-- Step 1: Define the basic 1-bit full adder component. [cite: 152]
ENTITY my_adder IS
    PORT(
        [cite_start]a, b, cin : IN  std_logic;      -- 1-bit inputs A, B, and Carry-In [cite: 166]
        [cite_start]s, cout   : OUT std_logic       -- 1-bit outputs Sum and Carry-Out [cite: 167]
    );
END ENTITY my_adder;

ARCHITECTURE a_my_adder OF my_adder IS
BEGIN
    [cite_start]s    <= a XOR b XOR cin; [cite: 171]
    [cite_start]cout <= (a AND b) OR (cin AND (a XOR b)); [cite: 172]
END ARCHITECTURE a_my_adder;


-- Step 2: Define a GENERIC N-bit adder.
[cite_start]-- A GENERIC allows you to pass parameters (like the width 'n') into your entity. [cite: 23]
ENTITY my_nadder IS
    GENERIC (
        [cite_start]n : integer := 8 -- 'n' is a parameter with a default value of 8. [cite: 250]
    );
    PORT (
        [cite_start]a, b : IN  std_logic_vector(n-1 DOWNTO 0); -- Port sizes are now dependent on 'n'. [cite: 254]
        [cite_start]cin  : IN  std_logic; [cite: 255]
        [cite_start]s    : OUT std_logic_vector(n-1 DOWNTO 0); [cite: 256]
        cout : OUT std_logic
    );
END ENTITY my_nadder;


-- Step 3: Use FOR...GENERATE to build the N-bit adder's architecture.
[cite_start]-- This creates N copies of our 1-bit adder component. [cite: 24]
ARCHITECTURE a_my_nadder OF my_nadder IS
    [cite_start]-- Declare the 1-bit adder as a component to be used (instantiated). [cite: 210]
    COMPONENT my_adder IS
        [cite_start]PORT(a, b, cin: IN std_logic; s, cout: OUT std_logic); [cite: 211]
    END COMPONENT;

    -- Internal "wires" to connect the carry from one adder to the next.
    [cite_start]-- Size is n+1 to accommodate the initial cin and the final cout. [cite: 280]
    [cite_start]SIGNAL temp : std_logic_vector(n DOWNTO 0); [cite: 280]

BEGIN
    -- Connect the main carry-in to the start of our internal carry chain.
    [cite_start]temp(0) <= cin; [cite: 295]

    [cite_start]-- The GENERATE statement creates 'n' instances of the my_adder component. [cite: 296]
    [cite_start]-- This is NOT a software loop; it describes 'n' physical copies of the hardware. [cite: 310]
    adder_gen_loop: FOR i IN 0 TO n-1 GENERATE
        -- For each 'i' from 0 to n-1, create one instance of my_adder named 'fx'.
        -- The PORT MAP connects the component's ports to the signals in this architecture.
        fx: my_adder PORT MAP(
            a    => a(i),       -- Connect i-th bit of input 'a'
            b    => b(i),       -- Connect i-th bit of input 'b'
            cin  => temp(i),    -- The carry-in for this bit comes from the previous bit's carry-out
            s    => s(i),       -- Connect to the i-th bit of output 's'
            cout => temp(i+1)   -- The carry-out for this bit connects to the next bit's carry-in
        );
    END GENERATE adder_gen_loop;

    [cite_start]-- Connect the final carry-out from the last adder to the main output port. [cite: 300]
    [cite_start]cout <= temp(n); [cite: 300]

END ARCHITECTURE a_my_nadder;

-- Step 4: How to USE (instantiate) the generic adder.
[cite_start]-- When you use my_nadder in another design, you can set 'n' with GENERIC MAP. [cite: 315]
-- Example: To create a 16-bit adder instance named 'u0':
[cite_start]-- u0: my_nadder GENERIC MAP (n => 16) PORT MAP (a => my_a, b => my_b, ...); [cite: 316]