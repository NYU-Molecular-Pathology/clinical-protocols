
# assuming Pyton 2.7
venv:
	unset PYTHONPATH ; \
	virtualenv venv --no-site-packages ; \
	. venv/bin/activate ; \
	pip install awscli --upgrade 

AWS_S3_FILE:=/ifs/data/molecpathlab/private_data/NGS580-S3.txt
# ABCDEF12345
AWS_ACCESS_KEY_ID:=$(shell cat "$(AWS_S3_FILE)" | grep -w access_key | cut -f2)
# +oABcdER12ghFGxl
AWS_SECRET_ACCESS_KEY:=$(shell cat "$(AWS_S3_FILE)" | grep -w secret_access_key | cut -f2)
# s3://ab-cd-123ffg6-30g
AWS_S3_BUCKET_URL:=$(shell cat "$(AWS_S3_FILE)" | grep -w bucket_url | cut -f2)

# https://docs.aws.amazon.com/cli/latest/reference/s3/ls.html
ls: venv
	unset PYTHONPATH ; \
	source venv/bin/activate ; \
	export AWS_ACCESS_KEY_ID="$(AWS_ACCESS_KEY_ID)" ; \
	export AWS_SECRET_ACCESS_KEY="$(AWS_SECRET_ACCESS_KEY)" ; \
	aws s3 ls --recursive --human-readable --summarize $(AWS_S3_BUCKET_URL)
	

configure:
	unset PYTHONPATH ; \
	source venv/bin/activate ; \
	export AWS_ACCESS_KEY_ID="$(AWS_ACCESS_KEY_ID)" ; \
	export AWS_SECRET_ACCESS_KEY="$(AWS_SECRET_ACCESS_KEY)" ; \
	aws configure



