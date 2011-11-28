module Smoke
  module Server
    class Error < AbstractResponse
      def initialize(env, code = :NotImplemented, resource = "/")
        #pp responses.inspect
        @code = code.to_s
        @resource = resource
        super
      end
      
      def responses
        {
          :AccessDenied => [403,"Access Denied"],
          :AccountProblem => [403,"There is a problem with your AWS account that prevents the operation from completing successfully. Please contact us."],
          :AmbiguousGrantByEmailAddress => [400, "The e-mail address you provided is associated with more than one account"],
          :BadDigest => [400, "The Content-MD5 you specified did not match what we received."],
          :BucketAlreadyExists => [409, "The requested bucket name is not available.  The bucket namespace is shared by all users of the system.  Please select a different name and try again."],
          :BucketAlreadyOwnedByYou => [409, "Your previous request to create the named bucket succeeded and you already own it."],
          :BucketNotEmpty => [409, "The bucket you tried to delete is not empty."],
          :BredentialsNotSupported => [400, "The request does not support credentials."],
          :CrossLocationLoggingProhibited => [403, "Cross location logging not allowed.  Buckets in one geographic location cannot log information to a bucket in another location."],
          :EntityToSmall => [400, "Your proposed upload is smaller than the minimum allowed size."],
          :EntityToLarge => [400, "Your proposed upload exceeds the maximum allowed object size."],
          :ExpiredToken => [400, "The provided token has expired."],
          :IllegalVersioningConfiguration => [400, "The versioning configuration specified in the request is invalid."],
          :IncompleteBody => [400, "You did not provide the number of bytes specified by the Content-Length HTTP header."],
          :IncorrectNumberOfFilesInPostRequest => [400, "POST requires exactly one file upload per request."],
          :InlineDataTooLarge => [400, "Inline data exceeds the maximum allowed size."],
          :InternalError => [500, "We encountered an internal error.  Please try again."],
          :InvalidAccessKeyId => [403, "The access key ID you provided does not exist in our records."],
          :InvalidAddressingHeader => [500, "You must specify the the Anonymous role."],
          :InvalidArgument => [400, "Invalid argument."],
          :InvalidBucketName => [400, "The specified bucket is not valid."],
          :InvalidDigest => [400, "The Content-MD5 you specified was invalid."],
          :InvalidLocationConstraint => [400, "The specified location constraint is not valid."],
          :InvalidPart => [400, "One or more of the specified parts could not be found.  The part might not have been uploaded, or the specified entity tag might not have matched the part's entity tag."],
          :InvalidPartOrder => [400, "The list of parts was not in ascending order.  Parts list must specify in order of part number."],
          :InvalidPolicyDocument => [400, "The content of the form does not meet the conditions specified in the policy document."],
          :InvalidRange => [416, "The requested range could not be satisfied."],
          :InvalidRequest => [400, "Invalid request."],
          :InvalidSecurity => [403, "The provided security credentials are not valid."],
          :InvalidStorageClass => [400, "The storage class you specified is not valid."],
          :InvalidTargetBucketForLogging => [400, "The target bucket for logging does not exist, is not owned by you, or does not have the appropriate grants for the log-delivery group."],
          :InvalidToken => [400, "The provided token is malformed or is otherwise invalid."],
          :InvalidURI => [400, "Could not parse the specified URI."],
          :KeyTooLong => [400, "Your key is too long"],
          :MalformedACLError => [400, "The XML you provided was not well-formed or did not validate against our published schema."],
          :MalformedPostRequest => [400, "The body of your post request is not well formed multipart/form-data."],
          :MalformedXML => [400, "The XML you provided was not well-formed or did not validate against our published schema."],
          :MaxMessageLengthExceeded => [400, "Your request was too big."],
          :MaxPostPreDataLengthExceededError => [400, "Your POST request fields preceeding the upload file were too large."],
          :MetadataTooLarge => [400, "Your metadata headers exceeded the maximum allowed metadata size."],
          :MethodNotAllowed => [405, "The specified method is not allowed against this resource."],
          :MissingContentLength => [411, "You must provide the Content-Length HTTP header."],
          :MissingRequestBody => [400, "Request body is empty."],
          :MissingSecurityHeader => [400, "Your request was missing a required header."],
          :NoLoggingStatusForKey => [400, "There is no such thing as a logging status sub-resource for a key."],
          :NoSuchBucket => [404, "The specified bucket does not exist."],
          :NoSuchKey => [404, "The specified key does not exist."],
          :NoSuchUpload => [404, "The specified multipart upload does not exist.  The upload ID might be invalid, or the multipart upload might have been aborted or completed."],
          :NoSuchVersion => [404, "The version ID specified in the request does not match an existing version."],
          :NotImplemented => [501, "A header you provided implies a functionality that is not implemented."],
          :NotSignedUp => [403, "Your account is not signed up for the service."],
          :NoSuchBucketPolicy => [404, "The specified bucket does not have a bucket policy."],
          :OperationAborted => [409, "A conflicting conditional operation is currently in progress against this resource.  Please try again."],
          :PermanentRedirect => [301, "The bucket you are attempting to access must be addressed using the specified endpoint.  Please send all future requests to this endpoint."],
          :PreconditionFailed => [412, "At least one of the preconditions you specified did not hold."],
          :Redirect => [307, "Temporary redirect."],
          :RequestIsNotMultipartContent => [400, "Bucket POST must be of the enclosure-type multipart/for-data."],
          :RequestTimeout => [400, "Your socket connection to the server was not read from or written to within the timeout period."],
          :RequestTimeTooSkewed => [403, "The difference between the request time and the servers time is too large."],
          :SignatureDoesNotMatch => [403, "The request signature we calculated does not match the signature you provided."],
          :SlowDown => [503, "Please reduce your request rate."],
          :TemporaryRedirect => [307, "You are being temporarily redirected to the bucket while DNS updates."],
          :TokenRefreshRequired => [400, "The provided token must be refreshed."],
          :TooManyBuckets => [400, "You have attempted to create more buckets than allowed."],
          :UnexpectedContent => [400, "The request does not support content."],
          :UnresolvableGrantByEmailAddress => [400, "The email address you provided does not match any account on record."],
          :UserKeyMustBeSpecified => [400, "The bucket POST must contain the specified field name.  If specified, please check the order of the fields."]
        }
      end
    end
  end
end