-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.02.2021 10:04:39
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
    use IEEE.std_logic_unsigned.ALL;
    use IEEE.numeric_std.ALL;
    use IEEE.math_real.ALL;
    
    
    entity project_reti_logiche is
        Port ( i_clk : in STD_LOGIC;
               i_rst : in STD_LOGIC;
               i_start : in STD_LOGIC;
               i_data : in STD_LOGIC_VECTOR (7 downto 0);
               o_address : out STD_LOGIC_VECTOR (15 downto 0);
               o_done : out STD_LOGIC;
               o_en : out STD_LOGIC;
               o_we : out STD_LOGIC;
               o_data : out STD_LOGIC_VECTOR (7 downto 0));
    end project_reti_logiche;
    
    architecture Behavioral of project_reti_logiche is
    
    type state_type is (
      START,      --stato iniziale della MSF
      START_READ,   -- inizio lettura, prendo indirizzo di cui ho bisogno
      DELAY,  --stato di attesa aggiornamento segnali, per creare una sorta di delay
      INCREASE,
      READ,  --stato in cui leggo da memoria il pixel 
      CALCULATE_MAX_AND_MIN,
      WRITE,
      WRITE_EQUALIZATION,
      EQUALIZATION,
      DONE_UP,
      DONE_DOWN);
                        
                      
                        
    signal state, current_state : state_type;
    signal current_address : std_logic_vector(15 downto 0);
    signal column : unsigned(7 downto 0);
    signal row : unsigned(0 to 7);
    signal max_pixel_value,min_pixel_value,delta_value : integer range 0 to 255;
    --signal temp_pixel : unsigned (7 downto 0); --:= "00000010";
    --signal new_pixel_value : integer range 0 to 255:=0;
    signal current_pixel_value : unsigned(7 downto 0);
    signal step : integer;
    signal shift_level : integer range 0 to 8:=0; 
    signal dim_img: integer; --aggiunto
                    
    begin
    process(i_clk ,i_rst)
    
    --variable step : integer;
    --variable current_address : std_logic_vector(15 downto 0);
    --variable current_pixel_value : unsigned(7 downto 0);
    --variable max_pixel_value,min_pixel_value,delta_value : integer range 0 to 255;
    --variable column : unsigned(7 downto 0);
    --variable row : unsigned(0 to 7);
    variable temp_pixel : unsigned (15 downto 0); 
    variable new_pixel_value : unsigned (7 downto 0);
    --variable shift_level : integer range 0 to 8; 
    --variable dim_img: integer range 0 to 16384; --aggiunto
          
          begin
          
          
          if(i_rst = '1')then
            
            o_en <= '0';
            o_we <= '0';
            o_done <= '0';
            current_address <= "0000000000000000";
            step <= 0;
            current_pixel_value <= "00000000";
            max_pixel_value <= 0;
            min_pixel_value <= 0;
            row <= "00000000";
            column <= "00000000";
            temp_pixel := "0000000000000000";
            new_pixel_value := "00000000";
            shift_level <= 0;
            dim_img <= 0;
            current_state <= START;
            state <= START;
            
          --end if;
            
          --if (i_clk 'event and i_clk='1') then
           elsif (i_clk 'event and i_clk='1') then
            case state is 
                when START =>
                    --stato inizio di tutto il processo, dopo un reset e a tocco di clock
                  
                     if (i_start = '1' AND i_rst = '0') then
                 
                             current_address <= "0000000000000000";
                             step <= 0;
                             current_pixel_value <= "00000000";
                             max_pixel_value <= 0;
                             min_pixel_value <= 0;
                             row <= "00000000";
                             column <= "00000000";
                             temp_pixel := "0000000000000000";
                             new_pixel_value := "00000000";
                             shift_level <= 0;
                             dim_img <= 0;     
                             o_en <= '0';
                             o_we <= '0';
                             current_state <= START; 
                             state <= DELAY;                   
                        end if;                    
                    
                when DELAY =>
           
                    --o_address <= current_address;
                    --state <= INCREASE;
                    
                    if (current_state = START) then
                        state <= START_READ;
                    elsif(current_state = START_READ) then
                        state <= READ;    
                    elsif(current_state = READ) then
                        dim_img <= TO_INTEGER(column)*TO_INTEGER(row);
              			state <= START_READ;
                    elsif(current_state = CALCULATE_MAX_AND_MIN) then
              			state <= CALCULATE_MAX_AND_MIN;
                    elsif (current_state = EQUALIZATION) then
                        state <= EQUALIZATION;
                    elsif (current_state = WRITE_EQUALIZATION) then
                        state <= WRITE;   
                    --elsif (current_state = DONE_UP) then
                        --state <= DONE_UP;
                    elsif ( current_state = WRITE) then     
                         if (step < (dim_img * 2) + 2) then          --non ho finito di equalizzare, devo rileggere alcuni pixel e trasformarli, controlla num step e quindi if(prima +1 ora ho incrementato prima)
                            --current_address <= current_address + "0000000000000001";
                            state <= START_READ;
                         else
                            state <= DONE_UP;
                         end if;        
                        
                    end if;
                    
                when START_READ =>
                     o_en <= '1';
                     o_we <= '0';
                     o_address <= current_address;
                     state <= DELAY;
                     current_state <= START_READ;          
                    
                when INCREASE => 
                --incemento il contatore per tener traccia dell' evoluzione 
                    step <= step + 1;
                    current_address <= current_address + "0000000000000001";                                                              
                    state <= DELAY;
                    
                when READ => 
              		o_en <= '1';
              		o_we <= '0';
                    if (step = 0) then           --primo passo, sto leggendo indir 0 quindi il primo byte == il numero di colonne
                        column <= unsigned(i_data);
                        --step <= step + 1;
                 		--current_address <= current_address + "0000000000000001"; 
                        state <= INCREASE;
                        current_state <= READ;
                        
                          
              		elsif ( step = 1) then        --secondo passo, sto leggendo indr 1 quindi il secondo byte == numero righe    
                        row <= unsigned (i_data);
              			--dim_img <= TO_INTEGER(column)*TO_INTEGER(row);                 --mi salvo la dimensione dell'immagine
                        --step <= step + 1;
                 		--current_address <= current_address + "0000000000000001"; 
                        state <= INCREASE;
                        current_state <= READ;  
                    
                                             
                    elsif ((step > 1) and (step < dim_img + 2)) then    --qui sono dall'indirizzo 2 in poi, fino a dim+1 ovvero ultimo pixel da leggere da memoria
                        current_pixel_value <= unsigned(i_data);
              			--step <= step + 1;
                 		--current_address <= current_address + "0000000000000001"; 
              			state <= DELAY;
                        current_state <= CALCULATE_MAX_AND_MIN;
                        
                        
              		elsif (step > dim_img + 1) then       --qui sono allo step di inizio equalizzazione e scrittura, il current address si trova alla prima riga vuota (dove scrivere)
                        if (dim_img = 0) then
                            state <= DONE_UP;
                        else    
                            o_address <= std_logic_vector(unsigned(current_address) - dim_img);
                            --current_pixel_value <= unsigned(i_data);                --dovrebbe prendere quello dell'immagine quindi all'indirizzo alla riga sopra, bisogna controllare di non doverlo fare nello stato dopo
                            delta_value <= max_pixel_value - min_pixel_value;  
                            state <= DELAY;
                            current_state <= EQUALIZATION;
                        end if;
                     
                    end if;
                    
     
                    
               when CALCULATE_MAX_AND_MIN =>
              	   o_en <= '1';
                   o_we <= '0';
                   
              	   if (step = 2) then        --essendo il primo pixel max e min li inizializzo pari a questo
                        
                        max_pixel_value <= TO_INTEGER(current_pixel_value); 
                        min_pixel_value <= TO_INTEGER(current_pixel_value);
                        state <= INCREASE;
                        current_state <= READ;
                        
                        
                   else
                        
                        if ( TO_INTEGER(current_pixel_value) > max_pixel_value ) then
                            max_pixel_value <= TO_INTEGER(current_pixel_value);
                        
                        elsif ( TO_INTEGER(current_pixel_value) < min_pixel_value) then
                             min_pixel_value <= TO_INTEGER(current_pixel_value);
                        
                        end if;
                        state <= INCREASE;
                        current_state <= READ;
                    
                    end if; 
                    --step <= step + 1;
                 	--current_address <= current_address + "0000000000000001";   
                             
                        
              
                when EQUALIZATION =>
                   
              	   o_en <= '1';
                   o_we <= '0';
                   
                   
                   if (delta_value = 0 ) then
                        shift_level <= 8;
                   elsif ((delta_value = 1) or (delta_value = 2)) then
                        shift_level <= 7;
                   elsif ((delta_value > 2) and (delta_value < 7)) then
                        shift_level <= 6;
                   elsif ((delta_value > 6) and (delta_value < 15)) then
                        shift_level <= 5;
                   elsif ((delta_value > 14) and (delta_value < 31)) then
                        shift_level <= 4;
                   elsif ((delta_value > 30) and (delta_value < 63)) then
                        shift_level <= 3;
                   elsif ((delta_value > 62) and (delta_value < 127)) then
                        shift_level <= 2;
                   elsif ((delta_value > 126) and (delta_value < 255)) then
                        shift_level <= 1;
                   else
                        shift_level <= 0;
                        
                   end if;
                   
                   current_pixel_value <= unsigned(i_data);
                   --temp_pixel := (current_pixel_value - min_pixel_value) sll shift_level;
                   
                   --if ( TO_INTEGER(temp_pixel) < 255) then
                        --new_pixel_value := temp_pixel;
                   --else
                        --new_pixel_value := "11111111";
                       
                   --end if;
                   
                   --o_address <= current_address;
                   --o_data <= std_logic_vector(new_pixel_value);
                   state <= WRITE_EQUALIZATION;
               
                   --shift_level <= 8 - integer(floor(log2(real(delta_value) + real(1))));   --non va il floor
                   --temp_pixel <= shift_left((current_pixel_value - min_pixel_value), shift_level); --mi prende 0-254 = 2
                   --temp_pixel <=  unsigned((current_pixel_value - TO_UNSIGNED(min_pixel_value,8) sll shift_level)) ;
                   --temp_pixel <= unsigned((current_pixel_value - min_pixel_value) sll shift_level);
                   --temp_pixel <= "10000000";
                   --o_address <= current_address; --rimetto l'indirizzo in cui andrò a scrivere
              
              
    
                when WRITE_EQUALIZATION =>
              
              	   o_en <= '1';
                   o_we <= '0';
                   temp_pixel := "00000000"&(current_pixel_value - min_pixel_value);
                   temp_pixel := temp_pixel sll shift_level;
                   
                   if ( TO_INTEGER(temp_pixel) < 255) then
                        new_pixel_value  := temp_pixel(7 downto 0);
                   else
                        new_pixel_value := "11111111";
                       
                   end if;
                    
                   o_address <= current_address;     --rimetto indirizzo in fondo, primo libero dove scrivere new pixel
                   --o_data <= std_logic_vector(new_pixel_value);    --salvo in memoria il nuovo pixel, ma lo farà nello stato di WRITE
                   state <= DELAY;
                   current_state <= WRITE_EQUALIZATION;
                  
                    -- o_address <= current_address; -- + std_logic_vector(row*column);
                    --o_data <= std_logic_vector(TO_UNSIGNED(new_pixel_value,8));
                    --o_data <= std_logic_vector(new_pixel_value);
                    
                    --if ( step < (dim_img*2) + 2) then
                         --current_state <= WRITE_EQUALIZATION;
                
                    --else
                         --current_state <= DONE_UP;
                    
                    --end if;
                    
                    
               when WRITE =>
              		 o_en <= '1';
                     o_we <= '1';
              		 --step <= step +1;
                     --current_address <= current_address + "0000000000000001"; 
                     o_data <= std_logic_vector(new_pixel_value);
                     state <= INCREASE;
                     current_state <= WRITE;
                    
                    
                when DONE_UP =>
                    o_done <= '1';
                    o_en <= '0';
                    o_we <= '0';
                    if (i_start = '0') then
                        state <= DONE_DOWN;
                    else
                        state <= DONE_UP;
                    end if;
                    
                    
                when DONE_DOWN =>
                    o_done <= '0';
                    if (i_start = '1') then
                        state <= START;
                    else
                        state <= DONE_DOWN;
                    end if;   
                
                
                
             end case;
           end if;
        end process; 
  end Behavioral;


