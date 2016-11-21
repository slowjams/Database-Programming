create or replace 
PROCEDURE DESTBANKFile
IS
v_filePointer utl_file.file_type;
v_utlDir VARCHAR2(35) := 'XL_DIR'; 
v_utlFileName VARCHAR2(35);
v_pageNr NUMBER := 1;
v_pageWidth NUMBER := 120;
v_organisationName Varchar2(50);
v_organisationAccount Varchar2(16);
v_count number:=0;
v_date Varchar2(6):=to_char(sysdate,'DDMMYY');
v_total_credit number:=0;

cursor c_merchant_details is select f2.merchantid m_id, merchantaccounttitle account_title, substr(merchantbankbsb,1,3)||'-'
||substr(merchantbankbsb,4,3)||merchantbankaccnr account_number, amount credit, lodgementref,printstatus
from fss_merchant f1, fss_daily_settlement f2 where printstatus='F' and f1.merchantid=f2.merchantid and trunc(settlementdate)=trunc(sysdate);
r_merchant_details c_merchant_details%ROWTYPE;

BEGIN

SELECT ORGACCOUNTTITLE,substr(ORGBSBNR,1,3)||'-'||substr(ORGBSBNR,4,3)||ORGBANKACCOUNT into v_organisationName, v_organisationAccount from FSS_ORGANISATION;

SELECT 'DS_'||to_char(sysdate,'DDMMYYYY')||'_XL'||'.dat' INTO v_utlFileName FROM dual;

v_filePointer := utl_file.fopen(v_utlDir, v_utlFileName, 'W');
utl_file.put_line(v_filePointer,RPAD('0',18)||'01'||'WBC'||LPAD('S/CARD BUS PAYMENTS',26)||LPAD('038559',13)||'INVOICES'||LPAD(v_date,10));
open c_merchant_details; 
LOOP
fetch c_merchant_details into r_merchant_details;
EXIT WHEN c_merchant_details%NOTFOUND;
utl_file.put_line(v_filePointer,'1'||r_merchant_details.account_number||' '||'50'||LPAD(r_merchant_details.credit,10,'0')||RPAD(r_merchant_details.account_title,33)||'F '||r_merchant_details.lodgementref||'032-797   001006'||'SMARTCARD TRANS '||RPAD('0',8,'0') );
UPDATE FSS_DAILY_SETTLEMENT
   SET PRINTSTATUS = 'T'
   WHERE LODGEMENTREF=r_merchant_details.LODGEMENTREF;

v_total_credit:=v_total_credit+r_merchant_details.credit;   
v_count:=v_count+1;
END LOOP;
close c_merchant_details;

utl_file.put_line(v_filePointer,'1'||v_organisationAccount||' '||'13'||LPAD(v_total_credit,10,'0')||RPAD(v_organisationName,33)||'N '||'800500000000000'||'032-797   001006'||'SMARTCARD TRANS '||RPAD('0',8,'0') );

v_count:=v_count+1;
utl_file.put_line(v_filePointer,'7'||RPAD('999-999',19)||RPAD('0',10,'0')||LPAD(v_total_credit,10,'0')||LPAD(v_total_credit,10,'0')||LPAD(' ',20)||LPAD(v_count,6,'0'));
utl_file.fclose(v_filePointer);

EXCEPTION
WHEN  OTHERS THEN
utl_file.fclose(v_filePointer);
common.log('Unable to write Daily Banking Summary at DestBankSummary, error is ' || SQLERRM);
Update_RunTable(NULL,'FAIL','Unable to write Daily Banking Summary') ;
END;