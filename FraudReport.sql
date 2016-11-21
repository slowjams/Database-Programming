create or replace 
PROCEDURE FraudReport IS

TYPE t_card_rec IS RECORD
    (transactionnr    NUMBER,
     terminalid       VARCHAR2(10),
     cardid           VARCHAR2(17),
     transactiondate  DATE,
     cardoldvalue     NUMBER,
     cardnewvalue     NUMBER);
TYPE t_transaction_array is TABLE OF t_card_rec INDEX BY BINARY_INTEGER;
v_transaction_list t_transaction_array;
Cursor c_cardid is select cardid from FSS_DAILY_TRANSACTION group by cardid order by cardid;
Cursor c_suspect_transaction(p_cardid varchar2) is select transactionnr,terminalid,cardid,transactiondate, cardoldvalue,cardnewvalue from FSS_DAILY_TRANSACTION where cardid=p_cardid order by transactionnr ,cardid,transactiondate;
v_old_value number;
v_new_value number;
v_index_base CONSTANT NUMBER := 1;
v_counter NUMBER:=v_index_base;
v_count NUMBER:=1;

v_filePointer utl_file.file_type;
v_utlDir VARCHAR2(35) := 'XL_DIR'; 
v_utlFileName VARCHAR2(35);
v_pageNr NUMBER := 1;
v_pageWidth NUMBER := 100;
v_date Varchar2(11):=to_char(sysdate, 'DD-Mon-YYYY');

FUNCTION f_centre(p_text VARCHAR2)
RETURN VARCHAR2 IS
v_textWidth NUMBER;
BEGIN
 v_textWidth := LENGTH(p_text) / 2;
 RETURN LPAD(p_text, (v_pageWidth/2) + v_textWidth, ' ');
END;

Begin
FOR r_cardid IN c_cardid LOOP
   FOR r__suspect_transaction IN c_suspect_transaction(r_cardid.cardid) LOOP
   IF c_suspect_transaction%ROWCOUNT<>1 
   THEN
      v_old_value:=r__suspect_transaction.cardoldvalue;
      IF v_old_value <= v_new_value 
      Then
         v_new_value:=r__suspect_transaction.cardnewvalue;
      ELSE
         v_transaction_list(v_counter):=r__suspect_transaction;
         v_counter := v_counter+1;
         v_new_value:=r__suspect_transaction.cardnewvalue;
      END IF;
   ELSE
      v_new_value:=r__suspect_transaction.cardnewvalue;
   END IF;
   END LOOP;
END LOOP;

SELECT 'Fraud_'||to_char(sysdate,'DDMMYYYY')||'_XL'||'.dat' INTO v_utlFileName FROM dual;
v_filePointer := utl_file.fopen(v_utlDir, v_utlFileName, 'W');
utl_file.put_line(v_filePointer, f_centre('Fraud Report'));
utl_file.put_line(v_filePointer, 'Date '||v_date||LPAD('Page '||v_pageNr, 83));
utl_file.new_line(v_filePointer);
utl_file.put_line(v_filePointer, 'Transactionnr'||LPAD('Terminal ID',18)||LPAD('Card ID',18)||LPAD('Transaction Date',26)||LPAD('Old Value', 12)||LPAD('New Value', 12));
utl_file.put_line(v_filePointer,LPAD('-', 13,'-')||RPAD(' ',7)||LPAD('-', 11,'-')||RPAD(' ',6)||LPAD('-', 17,'-')||RPAD(' ',5)||LPAD('-', 16,'-')||'   '||RPAD('-',9,'-')||'   '||LPAD('-', 9,'-')) ;

LOOP
EXIT WHEN v_count> v_transaction_list.count;
utl_file.put_line(v_filePointer, v_transaction_list(v_count).transactionnr||RPAD(' ',15)||v_transaction_list(v_count).terminalid||RPAD(' ',7)||v_transaction_list(v_count).cardid||RPAD(' ',8)
||v_transaction_list(v_count).transactiondate||RPAD(' ',7)||LPAD(to_char(v_transaction_list(v_count).cardoldvalue/100,'999999.00'),9)||RPAD(' ',2)||LPAD(to_char(v_transaction_list(v_count).cardnewvalue/100,'999999.00'),10));
v_count:=v_count+1;
END LOOP;
utl_file.new_line(v_filePointer);
utl_file.new_line(v_filePointer);
utl_file.put_line(v_filePointer, 'Fraud Report file Name : '||v_utlFileName);
utl_file.put_line(v_filePointer, RPAD('Dispatch Date',19)||': '||v_date);
utl_file.put_line(v_filePointer, f_centre('*** End of Report ***'));
utl_file.fclose(v_filePointer);
EXCEPTION

WHEN  OTHERS THEN
utl_file.fclose(v_filePointer);
common.log('Unable to write Fraud Report, error is '|| SQLERRM);
Update_RunTable(NULL,'FAIL','Unable to write Fraud Report');
END;