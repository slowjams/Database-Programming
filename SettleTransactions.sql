create or replace PROCEDURE SETTLETRANSACTIONS(p_newSettlement IN OUT NUMBER)
IS

v_lodgement_id Number := to_char(sysdate, 'DDMMYYYY')||LPAD(seqid_key.NEXTVAL, 7, '0');

cursor c_merchant_Total is select f3.merchantid, sum(transactionamount) amount from FSS_DAILY_TRANSACTION f1, FSS_TERMINAL f2, FSS_MERCHANT f3
where f1.lodgementref IS NULL and f1.terminalid=f2.terminalid and f2.merchantid=f3.merchantid group by f3.merchantid order by f3.merchantid ;
r_merchant_total c_merchant_Total%ROWTYPE;

BEGIN


OPEN c_merchant_Total;  
LOOP
FETCH c_merchant_Total INTO r_merchant_Total;
EXIT WHEN c_merchant_Total%NOTFOUND;

IF CHECK_AMOUNT_DATE(r_merchant_Total.amount)
THEN
   INSERT
   INTO FSS_DAILY_SETTLEMENT(LODGEMENTREF,MERCHANTID,AMOUNT,SETTLEMENTDATE,PRINTSTATUS)
   VALUES (v_lodgement_id
         ,r_merchant_Total.MERCHANTID
         ,r_merchant_Total.amount
         ,sysdate
         ,'F');

   UPDATE FSS_DAILY_TRANSACTION
   SET LODGEMENTREF = v_lodgement_id
   WHERE TRANSACTIONNR IN(SELECT TRANSACTIONNR FROM FSS_DAILY_TRANSACTION F1, FSS_TERMINAL F2, FSS_MERCHANT F3 
                          WHERE F3.MERCHANTID=r_merchant_Total.MERCHANTID 
                          AND F1.TERMINALID=F2.TERMINALID 
                          AND F2.MERCHANTID=F3.MERCHANTID 
                          AND F1.LODGEMENTREF IS NULL);

v_lodgement_id:= to_char(sysdate, 'DDMMYYYY')||lpad(seqid_key.NEXTVAL, 7, '0'); 
p_newSettlement:=p_newSettlement+1;
END IF;
END LOOP;
close c_merchant_Total;

EXCEPTION

WHEN  OTHERS THEN
Rollback;
common.log('Error occurs at SettleTransactions, error is ' || SQLERRM);
Update_RunTable(NULL,'FAIL','Error occurs at SettleTransactions, error is ' || SQLERRM);
END;