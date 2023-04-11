import os
import logging
from PIL import Image, ImageDraw, ImageFont
import boto3

s3 = boto3.client('s3')
watermark_text = os.environ['WATERMARK_TEXT']
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def add_watermark(image):
    width, height = image.size
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype('/var/task/arial.ttf', 36)
    textwidth, textheight = draw.textsize(watermark_text, font)
    x = width - textwidth - 10
    y = height - textheight - 10
    draw.text((x, y), watermark_text, font=font)

def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        new_bucket = os.environ['DESTINATION_BUCKET']
        new_key = 'resized-' + key
        tmpkey = 'tmp/' + key
        
        try:
            s3.download_file(bucket, key, '/tmp/image.jpg')
            with Image.open('/tmp/image.jpg') as image:
                logger.info(f'Resizing image {key}...')
                image.thumbnail((800, 800))
                add_watermark(image)
                image.save('/tmp/resized-image.jpg')
            logger.info(f'Uploading file {new_key} to bucket {new_bucket}...')
            s3.upload_file('/tmp/resized-image.jpg', new_bucket, new_key)
            logger.info(f'Deleting file {key} from bucket {bucket}...')
            s3.delete_object(Bucket=bucket, Key=key)
            logging.info(f'Image {key} resized and uploaded to S3')
        except Exception as e:
            logging.error(f'Error processing image {key}: {e}')
            raise e
    logger.info('Lambda function finished.')   
    return {
        'statusCode': 200,
        'body': 'Image resized and uploaded to S3'
    }
