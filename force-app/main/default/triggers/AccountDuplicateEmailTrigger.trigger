trigger AccountDuplicateEmailTrigger on Account (before insert, before update) {
    if (Trigger.isInsert || Trigger.isUpdate) {
        AccountDuplicateEmailTriggerHandler.deleteDuplicateAccountsByEmail(Trigger.new);
    }
}