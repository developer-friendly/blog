ENTE_DB_USER=CHANGEME
ENTE_DB_PASSWORD=CHANGEME

ENTE_S3_B2_EU_CEN_KEY=ACCESS_KEY
ENTE_S3_B2_EU_CEN_SECRET=SECRET_KEY

# https://github.com/ente-io/ente
# go run tools/gen-random-keys/main.go
ENTE_KEY_ENCRYPTION=CHANGEME
ENTE_KEY_HASH=CHANGEME
ENTE_JWT_SECRET=CHANGEME

ENTE_SMTP_USERNAME=CHANGEME
ENTE_SMTP_PASSWORD=CHANGEME

aws ssm put-parameter --name '/ente/db/user' --value $ENTE_DB_USER --type SecureString --overwrite
aws ssm put-parameter --name '/ente/db/password' --value $ENTE_DB_PASSWORD --type SecureString --overwrite

aws ssm put-parameter --name '/ente/s3/b2-eu-cen/key' --value $ENTE_S3_B2_EU_CEN_KEY --type SecureString --overwrite
aws ssm put-parameter --name '/ente/s3/b2-eu-cen/secret' --value $ENTE_S3_B2_EU_CEN_SECRET --type SecureString --overwrite

aws ssm put-parameter --name '/ente/key/encryption' --value "$ENTE_KEY_ENCRYPTION" --type SecureString --overwrite
aws ssm put-parameter --name '/ente/key/hash' --value "$ENTE_KEY_HASH" --type SecureString --overwrite
aws ssm put-parameter --name '/ente/jwt/secret' --value "$ENTE_JWT_SECRET" --type SecureString --overwrite

aws ssm put-parameter --name '/ente/smtp/username' --value $ENTE_SMTP_USERNAME --type SecureString --overwrite
aws ssm put-parameter --name '/ente/smtp/password' --value $ENTE_SMTP_PASSWORD --type SecureString --overwrite
