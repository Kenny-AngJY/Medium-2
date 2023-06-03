import boto3

cf_client = boto3.client('cloudformation')

def describe_update_stacks(stack_name):
    
    response = cf_client.describe_stacks(StackName=stack_name)
    stack_dict = response["Stacks"][0]
    protected = stack_dict.get("EnableTerminationProtection")
    print(f"{stack_name}'s termination protection is {protected}.")
     
    if not protected:
        response = cf_client.update_termination_protection(
            EnableTerminationProtection = True,
            StackName = stack_name
        )
        print(f"Termination protection for {stack_name} is now activated.")


def lambda_handler(event, context):
    
    print(event)

    StackStatusFilter = ['CREATE_IN_PROGRESS','CREATE_COMPLETE','REVIEW_IN_PROGRESS',\
                        'ROLLBACK_COMPLETE','ROLLBACK_FAILED','ROLLBACK_IN_PROGRESS',\
                        'UPDATE_COMPLETE','UPDATE_COMPLETE_CLEANUP_IN_PROGRESS',\
                        'UPDATE_FAILED','UPDATE_IN_PROGRESS','UPDATE_ROLLBACK_COMPLETE',\
                        'UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS',\
                        'UPDATE_ROLLBACK_FAILED','UPDATE_ROLLBACK_IN_PROGRESS',\
                        'IMPORT_IN_PROGRESS','IMPORT_COMPLETE','IMPORT_ROLLBACK_IN_PROGRESS',\
                        'IMPORT_ROLLBACK_FAILED','IMPORT_ROLLBACK_COMPLETE']
    
    ### if the event is from scheduler, then check everything.
    if event.get("source") == "aws.eventbridge_scheduler_schedules_CFN_TerminationProtection":
        cf_response = cf_client.list_stacks(
            StackStatusFilter = StackStatusFilter
        )
    
        list_of_dictionaries = cf_response["StackSummaries"]
        
        for each_stack in list_of_dictionaries:
            stack_name = each_stack["StackName"]
            if not each_stack.get("RootId"): # If it is a nested/child stack, skip it. TP is enabled on the root/parent stack
                describe_update_stacks(stack_name)
    
    
    ### elseif from 'CloudFormation Stack Status Change', then just check that one stack
    elif event.get("source") == "aws.cloudformation":

        cloudformation_status = event["detail"]['status-details']['status']
        
        if cloudformation_status in StackStatusFilter:
            
            print(f"Check Cloudformation stack: {event['resources']} has a status of {cloudformation_status}.")
            stack_arn = event["resources"][0]
            find_first_slash = stack_arn.find("/") + 1
            find_second_slash = stack_arn.find("/", find_first_slash)
            stack_name = stack_arn[find_first_slash:find_second_slash]
            
            describe_update_stacks(stack_name)