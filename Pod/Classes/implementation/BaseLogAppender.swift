/**
 * @name            BaseLogAppender.swift
 * @partof          zucred AG
 * @description
 * @author	 		Vasco Mouta
 * @created			21/11/15
 *
 * Copyright (c) 2015 zucred AG All rights reserved.
 * This material, including documentation and any related
 * computer programs, is protected by copyright controlled by
 * zucred AG. All rights are reserved. Copying,
 * including reproducing, storing, adapting or translating, any
 * or all of this material requires the prior written consent of
 * zucred AG. This material also contains confidential
 * information which may not be disclosed to others without the
 * prior written consent of zucred AG.
 */

import Foundation

/**
A partial implementation of the `LogRecorder` protocol.

Note that this implementation provides no mechanism for log file rotation
or log pruning. It is the responsibility of the developer to keep the log
file at a reasonable size.
*/
public class BaseLogAppender: LogAppender
{
    /** The name of the `LogRecorder`, which is constructed automatically
    based on the `filePath`. */
    public let name: String

    /** The `LogFormatter`s that will be used to format messages for
    the `LogEntry`s to be logged. */
    public let formatters: [LogFormatter]

    /** The list of `LogFilter`s to be used for filtering log messages. */
    public let filters: [LogFilter]
    
    /** The GCD queue that should be used for logging actions related to
    the receiver. */
    public let queue: dispatch_queue_t

    /**
    Initialize a new `LogRecorderBase` instance to use the given parameters.

    :param:     name The name of the log recorder, which must be unique.

    :param:     formatters The `LogFormatter`s to use for the recorder.
    */
    public init(name: String, formatters: [LogFormatter] = [DefaultLogFormatter()], filters: [LogFilter] = [])
    {
        self.name = name
        self.formatters = formatters
        self.queue = dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL)
        self.filters = filters
    }
    
    public required convenience init?(configuration: Dictionary<String, AnyObject>) {
        if let config = self.dynamicType.configuration(configuration) {
            self.init(name:config.name, formatters:config.formatters, filters:config.filters)
        } else {
            return nil
        }
    }
    
    public class func configuration(configuration: Dictionary<String, AnyObject>) -> (name: String, formatters: [LogFormatter], filters: [LogFilter])?  {
        if let name = configuration[LogAppenderConstants.Name] as? String {
            var returnConfig:(name: String, formatters: [LogFormatter], filters: [LogFilter])
            returnConfig.name = name
            
            /// Appender Encoders
            returnConfig.formatters = []
            if let encodersConfig = configuration[LogAppenderConstants.Encoders] as? Dictionary<String, AnyObject> {
                if let patternsConfig = encodersConfig[PatternLogFormatterConstants.Pattern] as? Array<String> {
                    for pattern in patternsConfig {
                        if(pattern.isEmpty) {
                            returnConfig.formatters.append(PatternLogFormatter())
                        } else {
                            returnConfig.formatters.append(PatternLogFormatter(logFormat: pattern))
                        }
                    }
                }
            } else {
                returnConfig.formatters.append(DefaultLogFormatter())
            }
            /// Appender Filters
            returnConfig.filters = []
            if let filtersConfig = configuration[LogAppenderConstants.Filters] as? Array<Dictionary<String, AnyObject> > {
                for filterConfig in filtersConfig {
                    if let className = filterConfig[LogFilterConstants.Class] as? String {
                        if let swiftClass = NSClassFromString(className) as? LogFilter.Type {
                            if let filter = swiftClass.init(configuration: filterConfig) {
                                returnConfig.filters.append(filter)
                            }
                        }
                    }
                }
            }
            return returnConfig
        } else {
            return nil
        }
    }

    /**
    This implementation does nothing. Subclasses must override this function
    to provide actual log recording functionality.

    **Note:** This function is only called if one of the `formatters` 
    associated with the receiver returned a non-`nil` string.
    
    :param:     message The message to record.

    :param:     entry The `LogEntry` for which `message` was created.

    :param:     currentQueue The GCD queue on which the function is being 
                executed.

    :param:     synchronousMode If `true`, the receiver should record the
                log entry synchronously. Synchronous mode is used during
                debugging to help ensure that logs reflect the latest state
                when debug breakpoints are hit. It is not recommended for
                production code.
    */
    public func recordFormattedMessage(message: String, forLogEntry entry: LogEntry, currentQueue: dispatch_queue_t, synchronousMode: Bool)
    {
        precondition(false, "Must override this")
    }
    
    // MARK: - CustomDebugStringConvertible
    public var debugDescription: String {
        get {
            return "\(Mirror(reflecting: self).subjectType): \(name)"
        }
    }
}
