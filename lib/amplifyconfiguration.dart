const amplifyconfig = '''{
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "api": {
        "plugins": {
            "awsAPIPlugin": {
                "notesApi": {
                    "endpointType": "REST",
                    "endpoint": "https://jxiehopdvf.execute-api.us-east-2.amazonaws.com/dev",
                    "region": "us-east-2",
                    "authorizationType": "AWS_IAM"
                }
            }
        }
    },
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "UserAgent": "aws-amplify-cli/0.1.0",
                "Version": "0.1.0",
                "IdentityManager": {
                    "Default": {}
                },
                "CredentialsProvider": {
                    "CognitoIdentity": {
                        "Default": {
                            "PoolId": "us-east-2:14cb31e7-8259-43b0-844e-3def55f96bce",
                            "Region": "us-east-2"
                        }
                    }
                },
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "us-east-2_eh6r88yA6",
                        "AppClientId": "6ls9hkladcpf31qg4n5ncfbeim",
                        "Region": "us-east-2"
                    }
                },
                "Auth": {
                    "Default": {
                        "OAuth": {
                            "WebDomain": "typeimp3fa47cfd-3fa47cfd-dev.auth.us-east-2.amazoncognito.com",
                            "AppClientId": "6ls9hkladcpf31qg4n5ncfbeim",
                            "SignInRedirectURI": "https://typeimp3fa47cfd-3fa47cfd-dev.auth.us-east-2.amazoncognito.com/oauth2/idpresponse,http://localhost:8000/,myapp://callback/,exp://",
                            "SignOutRedirectURI": "https://typeimp3fa47cfd-3fa47cfd-dev.auth.us-east-2.amazoncognito.com/oauth2/idpresponse,http://localhost:8000/,myapp://signout/,exp://",
                            "Scopes": [
                                "phone",
                                "email",
                                "openid",
                                "profile",
                                "aws.cognito.signin.user.admin"
                            ]
                        },
                        "authenticationFlowType": "USER_SRP_AUTH",
                        "socialProviders": [
                            "GOOGLE"
                        ],
                        "usernameAttributes": [
                            "EMAIL"
                        ],
                        "signupAttributes": [
                            "EMAIL"
                        ],
                        "passwordProtectionSettings": {
                            "passwordPolicyMinLength": 8,
                            "passwordPolicyCharacters": []
                        },
                        "mfaConfiguration": "OFF",
                        "mfaTypes": [
                            "SMS"
                        ],
                        "verificationMechanisms": [
                            "EMAIL"
                        ]
                    }
                },
                "DynamoDBObjectMapper": {
                    "Default": {
                        "Region": "us-east-2"
                    }
                }
            }
        }
    },
    "storage": {
        "plugins": {
            "awsDynamoDbStoragePlugin": {
                "partitionKeyName": "userId",
                "sortKeyName": "categoryId",
                "sortKeyType": "S",
                "region": "us-east-2",
                "arn": "arn:aws:dynamodb:us-east-2:773623060459:table/categoriesTable-dev",
                "streamArn": "arn:aws:dynamodb:us-east-2:773623060459:table/categoriesTable-dev/stream/2025-06-28T04:53:15.572",
                "partitionKeyType": "S",
                "name": "categoriesTable-dev"
            }
        }
    }
}''';