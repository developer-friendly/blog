$ keto relation-tuple create ./permissions/
NAMESPACE       OBJECT          RELATION NAME   SUBJECT
endpoints       /api/v1/posts   POST            roles:admin#member
endpoints       /api/v1/posts   GET             roles:admin#member
endpoints       /api/v1/users   POST            roles:admin#member
endpoints       /api/v1/users   GET             roles:admin#member
endpoints       /api/v1/users   GET             auditbot@developer-friendly.blog
endpoints       /api/v1/posts   POST            roles:editor#member
endpoints       /api/v1/posts   GET             roles:editor#member
roles           admin           member          alice@developer-friendly.blog
roles           editor          member          bob@developer-friendly.blog
