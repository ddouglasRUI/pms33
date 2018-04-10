//ADDED Check Pickup Event - for Break Enforcement to warn if picking up another server's check. 
// - PJohnson 04/23/2012 

//86 90 91  - Edited from 80's SIM
//discount all wine on Tuesdays disc#754
// - JGuenther 08/18/2014
//Jerimy/Patty 2/13/2018 Applied WWD discount to Rest, Bar & Cafe only.

//VARIABLES
var EmpSeq			: A50  	//define employee sequence number - emp_seq
var query			: A1024 //define query string for each query
var EmpNumber		: A50 	//define employee number - object number
var serverIP		: A12 	//server IP address
var StrErr			: A50 	//error return from SQL 
var Result			: a50 //




//CHECK PICKUP EVENT
//warn if another server is picking up a check
Event Pickup_Check
    if @CKEMP <> @TREMP
      if @EMPLOPT[4] = 0
        errormessage "FYI - You do NOT own this check!"
      endif
    endif
 ENDEVENT
 
 
 
//-----------------------------------------------------------------------------------------

//////////////////////////////////////////////////////
//LAUNCH SPECIALS APPLICATION

////////////////////////////////
Event inq: 50
EmpNumber = @Tremp
call Get_Emp_Seq
call getserverinfo
//call PostTotals

	// ------ Load the SIMODBC.dll --------------------------------------
	var TipLaunch		  : n20 = 0
	//Var DLLname		      : A1024 = "\cf\micros\etc\TipLaunch.dll"
	//var dllname : a1024 = "d:\micros\res\pos\bin\tiplaunch.dll"
	Var ceExeFilename  : A1024 = ""
	var exeParams		  : A1024 = ""
	var dllResult		      :	A1024 = ""
	

	if TipLaunch = 0
		DLLLoad TipLaunch, "TipLaunch.dll"
		
	endif
	
	if TipLaunch = 0
		infomessage "Unable to Load TipLaunch.dll"
	else
		//infomessage "TipLaunch.dll successfully loaded!"
	endif


EmpSeq = trim(EmpSeq)
serverIP = trim(serverIP)

format exeParams as "http://",serverIP,"/Specials/Specials.aspx?emp_seq=",EmpSeq
//infomessage exeParams

//for CE client
DLLCALL TipLaunch, CallExeAndWait("iesample.exe",exeParams, ref dllResult)

//for Win32 client
//DLLCALL TipLaunch, CallExeAndWait("iexplorer.exe",exeParams, ref dllResult)
//infomessage "Did it work?"

	If dllResult > -1
	   Result = dllResult
	ElseIf dllResult = -1
	   ExitWithError "Undetermined error in _ListDisplay.exe"
	ElseIf dllResult = -2
	   ExitWithError "Could not open List Data File"
	ElseIf dllResult = -3
	   ExitWithError "Error in Dll"
	ElseIf dllResult = -4
	   ExitWithError "No params supplied to _ListDisplay.exe"
	ElseIf dllResult = -5
	   ExitWithError "_ListDisplay had an unknown error"
	ElseIf dllResult = -7
	   ExitWithError "Error returned from GetExitCodeProcess in dll"
	ElseIf dllResult = -9
	   ExitWithError "Dll could not create process for supplied Exe name"
	EndIf


EndEvent

///////////////////////////////////////////////////////////////////////////

 
 
////////////////////////////////////////////////////// 
//SEND STAY
EVENT inq:103

	call AUTODISCOUNT
	call SENDSTAY
    
ENDEVENT


/////////////////////////////////////////////////
// PRINT CHECK
//
event inq:101
    
	call AUTODISCOUNT
    call PRINTCHECK
    
ENDEVENT


////////////////////////////////////////////////
// send exit
//
event inq:102
	
	CALL AUTODISCOUNT
    CALL SENDEXIT
    
ENDEVENT
 



//////////////////////////////////////////////////////////////////////////////////////////
//Print all seats
//
event inq:111


var print_stay			: n7 = 906
var send_exit			: n7 = 901

//
// Static variables and constants
// (Please DO NOT EDIT THESE)
//

var filter_key			: key = key(1,589827)
var print_key			: key = key(10,print_stay)
var service_key			: key = key(10,send_exit)
var seat_loop			: n3
var dtl_loop			: n3
var seat_array[32]		: n3
var seat_inc			: n3 = 1

	for seat_loop = 1 to 128
		for dtl_loop = 1 to @numdtlt
			if @dtl_seat[dtl_loop] = seat_loop
				seat_array[seat_inc] = seat_loop
				seat_inc = seat_inc + 1
				break
			endif
		endfor
	endfor

	for seat_loop = 1 to (seat_inc - 1)
		loadkybdmacro makekeys(seat_array[seat_loop]), filter_key, print_key, @key_clear
	endfor
	loadkybdmacro service_key
	
endevent

//-----------------------------------------------------------------------------------------



 
////////////////////////////////////////////////
// Transfer Check
// IN DEVELOPMENT
event inq:110
	if @CKEMP <> @TREMP
      	exitwitherror "Only the check owner can transfer a check in"
    else
    	
    	loadkybdmacro key(1,393219), key(1,65537), @key_enter
    endif
endevent
    




//OFFLINE GIFT / COMP / LOYALTY CARD FUNCTIONS///////////////////////////
//----------------------------------------------------------------------

EVENT INQ : 120 //OFFLINE GIFT CARD REDEEM

  call PXWarningMessage
  
  loadkybdmacro key(10, 302)

EndEvent


EVENT INQ : 121 //OFLINE GC ACTIVATION

  call PXWarningMessage
  
  loadkybdmacro key(8,904)
  
ENDEVENT


EVENT INQ : 122 //OFFLINE RSC COMP CARD DISCOUNT

  call PXWarningMessage
  
  loadkybdmacro key(6, 358)

ENDEVENT


EVENT INQ : 123 //OFFLINE APOLOGY COMP DISCOUNT

  call PXWArningMessage
  
  loadkybdmacro key(6, 357)
  
ENDEVENT


EVENT INQ : 124 //OFFLINE GUEST COMP DISCOUNT
  call PXWarningMessage
  
  loadkybdmacro key(6, 359)

ENDEVENT
   

EVENT INQ : 125 //OFFLINE EDEC REWARD DISCOUNT
  call PXWarningMessage
  
  loadkybdmacro key(6, 304)
  

ENDEVENT







//SUBROUTINES///////////////////////////////////////////

sub PXWarningMessage
  INFOMESSAGE "REMEMBER TO CALL THIS TRANSACTION INTO PAYTRONIX"
endsub






sub PRINTCHECK
 
    loadkybdmacro key(10,902) //print check

endsub


sub SENDEXIT

   loadkybdmacro key(10,901) //SEND/EXIT
   
endsub


sub SENDSTAY
	
	loadkybdmacro key(10,903)  //SEND/STAY
	
endsub


sub AUTODISCOUNT

if @weekday = 2 
    var i : n6
    var mc : n6
    mc = 0
      for i = 1 to @numdtlt
		if @Dtl_Type[i] = "M"
		  if ((@RVC = 1 OR @RVC = 2 OR @RVC = 3) AND @Dtl_Famgrp[i] = 25 AND @DTL_IS_VOID[i] = 0)
		    mc = mc + @Dtl_Qty[i]
		  endif
		endif
        if @DTL_Type[i] = "D" AND @Dtl_is_void[i] = 0 AND @DTL_Object[i] = 754
          mc = mc - @Dtl_Qty[i]
        endif
      endfor
     if mc > 0
       loadkybdmacro key(6,754)
    endif
   endif
   
endsub




/////////////////////////////////////////////////
sub GetServerInfo

//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		if constatus = 0
			DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		

	format query as "select ip_addr from micros.lan_node_def where obj_num = 99"

	DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
	DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
		if len(query) < 1 then
			format strErr as "No Records"
		else
			split query, ";", serverIP
		endif
	
	DllFree hODBCDLL

endsub
/////////////////////////////////////////////////


/////////////////////////////////////////////////
Sub Get_Emp_Seq
	
//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		
		if constatus = 0
			DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		

	//  ------Query to get emp_seq
	format query as "SELECT emp_seq from micros.emp_def WHERE obj_num = ", EmpNumber

	DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
	DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
	format EmpSeq as query
	split EmpSeq, ";" , EmpSeq

		
	DllFree hODBCDLL	
EndSub

//////////////////////////////////////////////////////


