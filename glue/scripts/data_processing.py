import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get job arguments
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'S3_INPUT_PATH', 'S3_OUTPUT_PATH'])

job = None
try:
    # Initialize contexts
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    logger.info(f"Starting job: {args['JOB_NAME']}")
    logger.info(f"Input path: {args['S3_INPUT_PATH']}")
    logger.info(f"Output path: {args['S3_OUTPUT_PATH']}")

    # Read data from S3 (CSV format)
    logger.info("Reading data from S3...")
    datasource = glueContext.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={"paths": [args['S3_INPUT_PATH']]},
        format="csv",
        format_options={"withHeader": True}
    )

    record_count = datasource.count()
    logger.info(f"Read {record_count} records from source")

    if record_count == 0:
        logger.warning("No records found in input. Skipping Parquet write.")
    else:
        # For CSV to Parquet conversion, we'll just pass through all records
        transform = datasource

        # Write output back to S3 in Parquet format
        logger.info("Writing data to S3 in Parquet format...")
        glueContext.write_dynamic_frame.from_options(
            frame=transform,
            connection_type="s3",
            connection_options={"path": args['S3_OUTPUT_PATH']},
            format="parquet"
        )
        logger.info("Job completed successfully")

except Exception as e:
    logger.error("Error in Glue job", exc_info=True)
    raise
finally:
    if job:
        job.commit()