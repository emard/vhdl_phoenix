/*
#define CORE_TYPE_UNKNOWN   0x55
#define CORE_TYPE_DUMB      0xa0   // core without any io controller interaction
#define CORE_TYPE_MINIMIG   0xa1   // minimig amiga core
#define CORE_TYPE_PACE      0xa2   // core from pacedev.net (joystick only)
#define CORE_TYPE_MIST      0xa3   // mist atari st core   
#define CORE_TYPE_8BIT      0xa4   // atari 800/c64 like core
#define CORE_TYPE_MINIMIG2  0xa5   // new Minimig with AGA
#define CORE_TYPE_ARCHIE    0xa6   // Acorn Archimedes
*/

module user_io
(
  input        CLK, // fast clock, 200-250 MHz
  input        SPI_CLK,
  input        SPI_SS_IO,
  output       reg SPI_MISO,
  input        SPI_MOSI,
  input [7:0]  CORE_TYPE,
  output [5:0] JOY0,
  output [5:0] JOY1,
  output [1:0] BUTTONS,
  output [1:0] SWITCHES
);

reg [6:0]   sbuf;
reg [7:0]   cmd;
reg [4:0]   cnt;
reg [5:0]   joystick0;
reg [5:0]   joystick1;
reg [3:0]   but_sw;

assign JOY0 = joystick0;
assign JOY1 = joystick1;
assign BUTTONS = but_sw[1:0];
assign SWITCHES = but_sw[3:2];

reg [1:0] SPI_CLK_SHIFT;

always@(posedge CLK)
begin
  SPI_CLK_SHIFT <= {SPI_CLK, SPI_CLK_SHIFT[1]};
end
   
always@(posedge CLK)
begin
  // negedge SPI_CLK
  if(SPI_CLK_SHIFT == 2'b01)
  begin
    if(SPI_SS_IO == 1)
    begin
      SPI_MISO <= 1'bZ;
    end else begin
      if(cnt < 8)
      begin
        SPI_MISO <= CORE_TYPE[7-cnt];
      end else begin
        SPI_MISO <= 1'bZ;
      end
    end
  end
end
		
always@(posedge CLK)
begin
  // posedge SPI_CLK
  if(SPI_CLK_SHIFT == 2'b10)
  begin
    if(SPI_SS_IO == 1)
    begin
      cnt <= 0;
    end else begin
      sbuf[6:1] <= sbuf[5:0];
      sbuf[0] <= SPI_MOSI;
      cnt <= cnt + 1;

      if(cnt == 7) begin
        cmd[7:1] <= sbuf; 
        cmd[0] <= SPI_MOSI;
      end	

      if(cnt == 15) begin
        if(cmd == 1) begin
          but_sw[3:1] <= sbuf[2:0]; 
	  but_sw[0] <= SPI_MOSI; 
        end
        if(cmd == 2) begin
          joystick0[5:1] <= sbuf[4:0]; 
          joystick0[0] <= SPI_MOSI; 
        end
        if(cmd == 3) begin
          joystick1[5:1] <= sbuf[4:0]; 
          joystick1[0] <= SPI_MOSI; 
        end
      end	
    end
  end
end
   
endmodule
