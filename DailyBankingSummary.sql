create or replace 
PROCEDURE DAILYBANKINGSUMMARY(p_date IN DATE) 
IS
v_filePointer utl_file.file_type;
v_utlDir VARCHAR2(35) := 'XL_DIR'; 
v_utlFileName VARCHAR2(35);
v_pageNr NUMBER := 1;
v_pageWidth NUMBER := 95;
v_organisationName Varchar2(50);
v_organisationAccount Varchar2(16);
v_totalCredit number:=0;
v_date Varchar2(11):=to_char(p_date, 'DD-Mon-YYYY');

cursor c_merchant_details is select f2.merchantid m_id, merchantaccounttitle m_title, substr(merchantbankbsb,1,3)||'-'||substr(merchantbankbsb,4,3)||merchantbankaccnr account_number, amount/100 credit
from fss_merchant f1, fss_daily_settlement f2 where f1.merchantid=f2.merchantid and trunc(settlementdate)=trunc(p_date);
r_merchant_details c_merchant_details%ROWTYPE;
FUNCTION f_centre(p_text VARCHAR2)
RETURN VARCHAR2 IS
v_textWidth NUMBER;
BEGIN
 v_textWidth := LENGTH(p_text) / 2;
 RETURN LPAD(p_text, (v_pageWidth/2) + v_textWidth, ' ');
END;

BEGIN

 SELECT 'DBS_'||to_char(sysdate,'DDMMYYYY')||'_XL'||'.dat' INTO v_utlFileName FROM dual;

 v_filePointer := utl_file.fopen(v_utlDir, v_utlFileName, 'W');

 utl_file.put_line(v_filePointer, f_centre('SMARTCARD SETTLEMENT SYSTEM'));
 utl_file.put_line(v_filePointer, f_centre('DAILY DESKBANK SUMMARY'));
 utl_file.put_line(v_filePointer, 'Date '||v_date||LPAD('Page '||v_pageNr, 77));
 utl_file.new_line(v_filePointer);
 utl_file.put_line(v_filePointer, 'Merchant ID '||LPAD('Merchant Name',23)||LPAD('Account Number', 30)||LPAD('Debit ', 14)||LPAD('Credit ', 13));
 utl_file.put_line(v_filePointer,LPAD('-  ', 13,'-')||LPAD('-  ', 35,'-')||LPAD('-', 21,'-')||RPAD(' ',2)||LPAD('-   ', 13,'-')||LPAD('-', 9,'-'));
 
open c_merchant_details; 
LOOP
fetch c_merchant_details into r_merchant_details;
EXIT WHEN c_merchant_details%NOTFOUND;
utl_file.put_line(v_filePointer, r_merchant_details.m_id||RPAD(' ',6)||RPAD(r_merchant_details.m_title,35)||RPAD(r_merchant_details.account_number,31)||LPAD(to_char(r_merchant_details.credit,'999999.00'),12));
v_totalCredit:=v_totalCredit+r_merchant_details.credit;
END LOOP;
close c_merchant_details;
select ORGACCOUNTTITLE,substr(ORGBSBNR,1,3)||'-'||substr(ORGBSBNR,4,3)||ORGBANKACCOUNT into v_organisationName, v_organisationAccount from FSS_ORGANISATION;
utl_file.put_line(v_filePointer, LPAD(' ',15)||RPAD(v_organisationName,35)||RPAD(v_organisationAccount,20)||to_char(v_totalCredit,'999999.00'));
utl_file.put_line(v_filePointer,LPAD(' ',69)||RPAD('-',13,'-')||' '||LPAD('-',10,'-'));
utl_file.put_line(v_filePointer,RPAD('BALANCE TOTAL',70)||RPAD(to_char(v_totalCredit,'999999.00'),11)||LPAD(to_char(v_totalCredit,'999999.00'),12)); 
utl_file.new_line(v_filePointer);
utl_file.new_line(v_filePointer);
utl_file.put_line(v_filePointer, 'Deskbank file Name : '||v_utlFileName);
utl_file.put_line(v_filePointer, RPAD('Dispatch Date',19)||': '||v_date);
utl_file.put_line(v_filePointer, f_centre('*** End of Report ***'));
utl_file.fclose(v_filePointer);


EXCEPTION

WHEN  OTHERS THEN
utl_file.fclose(v_filePointer);
common.log('Unable to write Daily Banking Summary Report at DailyBankingSummary, error is ' || SQLERRM);
Update_RunTable(NULL,'FAIL','Unable to write Daily Banking Summary Report at DailyBankingSummary') ;
END;