create or replace 
PROCEDURE Update_RunTable(p_number IN NUMBER, p_outcome IN VARCHAR2, p_message IN VARCHAR2) 
IS

PRAGMA AUTONOMOUS_TRANSACTION;
v_run_id Number := runid_key.CURRVAL;

BEGIN

IF p_number IS NOT NULL
THEN
   INSERT
   INTO FSS_RUN_TABLE
   VALUES (p_number
          ,SYSDATE
          ,NULL
          ,NULL
          ,NULL);
ELSIF p_outcome='SUCCESS'
THEN
   UPDATE FSS_RUN_TABLE
   SET RUNEND=sysdate,
       RUNOUTCOME='SUCCESS',
       REMARKS=p_message
   WHERE RUNID = v_run_id;

ELSIF p_outcome='FAIL'
THEN
   UPDATE FSS_RUN_TABLE
   SET RUNEND=sysdate,
       RUNOUTCOME='FAIL',
       REMARKS=p_message
   WHERE RUNID = v_run_id;

END IF;

Commit;

EXCEPTION

WHEN  OTHERS THEN
common.log('Error occurs at updating the Run Table, error code ' || SQLERRM);
Update_RunTable(NULL,'FAIL','Error occurs at updating the Run Table');
END;