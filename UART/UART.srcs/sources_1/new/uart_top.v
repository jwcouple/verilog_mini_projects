`timescale 1ns / 1ps

module uart_top #(
    parameter   NBYTES        = 12,
    // values for the UART (in case we want to change them)
    parameter   CLK_FREQ      = 125_000_000,
    parameter   BAUD_RATE     = 115_200
  )  
  (
    input   wire   iClk, iRst,
    input   wire   iRx,
    output  wire   oTx
  );
  
  // Buffer to exchange data between Pynq-Z2 and laptop
  reg [NBYTES*8-1:0] rBuffer;

  
  // State definition  
  localparam s_IDLE         = 3'b000;
  localparam s_WAIT_RX      = 3'b001;
  localparam s_TX           = 3'b010;
  localparam s_WAIT_TX      = 3'b011;
  localparam s_DONE         = 3'b100;
  localparam s_RX           = 3'b101;
   
  // Declare all variables needed for the finite state machine 
  // -> the FSM state
  reg [2:0]   rFSM;  
  
  // Connection to UART TX (inputs = registers, outputs = wires)
  reg         rTxStart;
  reg [7:0]   rTxByte;
  
  wire        wTxBusy;
  wire        wTxDone;
  
  // Connection to UART RX (inputs = registers, outputs = wires)
  
  wire [7:0]  wRxByte;
  wire        wRxDone;
      
  uart_tx #(  .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE) )
  UART_TX_INST
    (.iClk(iClk),
     .iRst(iRst),
     .iTxStart(rTxStart),
     .iTxByte(rTxByte),
     .oTxSerial(oTx),
     .oTxBusy(wTxBusy),
     .oTxDone(wTxDone)
     );
  
  // instantiate module under test
  uart_rx #( .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE) ) 
  UART_RX_INST
    (.iClk(iClk),
     .iRst(iRst),
     .iRxSerial(oTx),
     .oRxByte(wRxByte),
     .oRxDone(wRxDone)
     );
        
  reg [$clog2(NBYTES):0] tCnt;
  reg [$clog2(NBYTES):0] rCnt;
  
  always @(posedge iClk)
  begin
  
  // reset all registers upon reset
  if (iRst == 1 ) 
    begin
      rFSM <= s_IDLE;
      rTxStart <= 0;
      tCnt <= 0;
      rTxByte <= 0;
      rCnt <= 0;
      rBuffer <= 0;
    end 
  else 
    begin
      case (rFSM)
   
        s_IDLE :
          begin
            rFSM <= s_WAIT_RX;
          end      
        
        s_WAIT_RX :
          begin    
            if(wRxDone) begin
                rBuffer <= {rBuffer[NBYTES*8-9:0],wRxByte};           // if the previous byte is recieved, continue to recieve new byte                                          
//                rBuffer[7:0] <= wRxByte;                            // we receive and store in position from [current_byte_number*8-1:current_byte_number*8-8] and shift from right to left
                rCnt <= rCnt+1;
                if (rCnt == NBYTES) begin
                    rFSM <= s_TX;                                     // if finished storing all bytes from TX. go back to TX state to allow furthur sending
                    rCnt <= 0;                                        // set byte count to 0 for next round
                end else begin
                    rFSM <= s_WAIT_RX;                                // else continue to receive remaining bytes
                end
            end
            else begin                                                // else if previous byte has not been fully recieved, stay in this state
                rFSM <= s_WAIT_RX;
            end
          end
             
        s_TX :                                                        // state to prepare the tx_Nbytes (save into buffer)
          begin
            if ( (tCnt < NBYTES) && (wTxBusy ==0) )                   // if tx line is not busy and bytes count < bytes_to_be_sent
              begin
                rFSM <= s_WAIT_TX;                                    // next state is to go wait_for_Nbytes_tx_to_be_done buffer state
                rTxStart <= 1; 
                rTxByte <= rBuffer[NBYTES*8-1:NBYTES*8-8];            // we send the uppermost byte
                rBuffer <= {rBuffer[NBYTES*8-9:0] , 8'b0000_0000};    // we shift from right to left
                tCnt <= tCnt + 1;                                     
              end 
            else 
              begin                                                   // tCnt == NBYTES && wTxBusy || wTxBusy == 1
                rFSM <= s_IDLE;                                    // finish preparing nbytes_tx_buffer, go to RX
                rTxStart <= 0;                                        // reset all buffers
                rTxByte <= 0;
                tCnt <= 0;
              end
          end 
            
        s_WAIT_TX :
          begin
            if (wTxDone) begin                                        // if tx_action_finished signal is recieved from uart_tx
              rFSM <= s_TX;                                           // if bytes preparation and sending is done, go to the next nBytes preparation state
            end else begin
              rFSM <= s_WAIT_TX;                                      // if the tx is still sending, wait still
              rTxStart <= 0;                                          // do not restart
            end
          end 
          
        s_DONE :
          begin
            rFSM <= s_DONE;                                           // finished sending
          end 

        default :
          rFSM <= s_IDLE;
             
      endcase
      end
    end       
    
endmodule
