var winston         = require('winston');
var Mail            = require("winston-mail").Mail;
winston.emitErrs    = true;

var logger = new winston.Logger({
    transports: [
        //new winston.transports.File({
        //    level: 'info',
        //    filename: './logs/server.log',
        //    handleExceptions: true,
        //    json: true,
        //    maxsize: 5242880, //5MB
        //    maxFiles: 5,
        //    colorize: false,
        //    timestamp: function() {
        //        return new Date();
        //    },
        //    formatter: function(options) {
        //        // Return string will be passed to logger.
        //        return options.timestamp().toISOString() +' '+ options.level.toUpperCase() +' '+ (undefined !== options.message ? options.message : '') +
        //            (options.meta && Object.keys(options.meta).length ? '\n\t'+ JSON.stringify(options.meta) : '' );
        //    }
        //}),
        new winston.transports.Console({
            timestamp: function() {
                return new Date();
            },
            formatter: function(options) {
                // Return string will be passed to logger.
                return options.timestamp().toISOString() +' '+ options.level.toUpperCase() +' '+ (undefined !== options.message ? options.message : '') +
                    (options.meta && Object.keys(options.meta).length ? '\n\t'+ JSON.stringify(options.meta) : '' );
            },
            level: 'debug',
            handleExceptions: true,
            json: false,
            colorize: true
        }),
        new winston.transports.Mail({
            level: 'error',
            host: 'smtp.corp.redhat.com',
            to: 'smendenh@redhat.com',
            from: 'smendenh@redhat.com',
            subject: 'quest error'
        })
    ],
    exitOnError: false
});
logger.exitOnError = false;

module.exports = logger;
module.exports.stream = {
    write: function(message, encoding){
        logger.info(message);
    }
};
