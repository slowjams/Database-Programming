create or replace 
FUNCTION  CHECK_AMOUNT_DATE(p_amount IN NUMBER) 
RETURN boolean
IS
minimum_amount NUMBER;
BEGIN
SELECT REFERENCEVALUE*100 INTO minimum_amount FROM FSS_REFERENCE WHERE REFERENCEID='DMIN';
IF TRUNC(SYSDATE)=TRUNC(LAST_DAY(SYSDATE))
THEN
   RETURN TRUE;
ELSIF p_amount> minimum_amount
THEN 
   RETURN TRUE;
ELSE
   RETURN FALSE;
END IF;
EXCEPTION
WHEN OTHERS THEN
Rollback;
common.log('Error occurs at check_amount_date, error is ' || SQLERRM);
Update_RunTable(NULL,'FAIL','Error occurs at check_amount_date') ;
END;