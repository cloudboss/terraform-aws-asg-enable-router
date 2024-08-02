import boto3


DETAIL_KEY = "detail"
DETAIL_TYPE_KEY = "detail-type"
INSTANCE_ID_KEY = "EC2InstanceId"
LAUNCH_SUCCESSFUL = "EC2 Instance Launch Successful"


def handler(event, _):
    detail_type = event.get(DETAIL_TYPE_KEY)
    if not detail_type:
        raise KeyError(f"{DETAIL_TYPE_KEY} not found in event")

    if detail_type != LAUNCH_SUCCESSFUL:
        return

    detail = event.get(DETAIL_KEY)
    if not detail:
        raise KeyError(f"{DETAIL_KEY} not found in event")

    instance_id = detail.get(INSTANCE_ID_KEY)
    if not instance_id:
        raise KeyError(f"{INSTANCE_ID_KEY} not found in event {DETAIL_KEY}")

    ec2 = boto3.client("ec2")
    ec2.modify_instance_attribute(
        InstanceId=instance_id, SourceDestCheck={"Value": False}
    )
