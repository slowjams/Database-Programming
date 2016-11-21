create or replace PROCEDURE DailySettlement 
IS
v_count_run number:=0;
v_count_running number:=0;
v_count_newSettlement Number:=0;
is_running exception;
already_run exception;
v_run_id Number := runid_key.NEXTVAL;
BEGIN

Update_RunTable(v_run_id, NULL, NULL);

SELECT count(*) into v_count_run from FSS_RUN_TABLE where runoutcome='SUCCESS' and trunc(runend)=trunc(sysdate);

SELECT count(*) into v_count_running from FSS_RUN_TABLE where runstart is not null and runend is null and trunc(runend)=trunc(sysdate);

IF v_count_run<>0
THEN
   raise already_run;
ELSIF v_count_running<>0
Then
   raise is_running;
ELSE
   INSERT
   INTO FSS_DAILY_TRANSACTION(TRANSACTIONNR,DOWNLOADDATE,TERMINALID,CARDID,TRANSACTIONDATE,CARDOLDVALUE,TRANSACTIONAMOUNT,CARDNEWVALUE,TRANSACTIONSTATUS,ERRORCODE,LODGEMENTREF)
   SELECT TRANSACTIONNR,DOWNLOADDATE,TERMINALID,CARDID,TRANSACTIONDATE,CARDOLDVALUE,TRANSACTIONAMOUNT,CARDNEWVALUE,TRANSACTIONSTATUS,ERRORCODE,NULL FROM FSS_TRANSACTIONS
   MINUS
   SELECT TRANSACTIONNR,DOWNLOADDATE,TERMINALID,CARDID,TRANSACTIONDATE,CARDOLDVALUE,TRANSACTIONAMOUNT,CARDNEWVALUE,TRANSACTIONSTATUS,ERRORCODE,NULL FROM FSS_Daily_TRANSACTION;
END IF;


SettleTransactions(v_count_newSettlement);
DestBankFile;
DailyBankingSummary(sysdate);
FraudReport;

Update_RunTable(NULL,'SUCCESS', 'The total number of new settlement is '||v_count_newSettlement);

COMMIT;

EXCEPTION

WHEN is_running THEN
common.log('Program is still running. Aborting this run');
Update_RunTable(NULL,'FAIL','Someone tried to run the program while it was still running.');

WHEN already_run THEN
common.log('Program already ran today');
Update_RunTable(NULL,'FAIL','Program already ran today');

WHEN  OTHERS THEN
Rollback;
common.log('The error is ' || SQLERRM);
Update_RunTable(NULL,'FAIL','The error is ' || SQLERRM);

END;