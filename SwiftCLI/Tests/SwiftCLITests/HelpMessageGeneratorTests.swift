//
//  CommandMessageGeneratorTests.swift
//  SwiftCLI
//
//  Created by Jake Heiser on 6/13/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import XCTest
@testable import SwiftCLI

class HelpMessageGeneratorTests: XCTestCase {
    
    static var allTests : [(String, (HelpMessageGeneratorTests) -> () throws -> Void)] {
        return [
            ("testCommandListGeneration", testCommandListGeneration),
            ("testMutlineCommandListGeneration", testMutlineCommandListGeneration),
            ("testUsageStatementGeneration", testUsageStatementGeneration),
            ("testLongDescriptionGeneration", testLongDescriptionGeneration),
            ("testInheritedUsageStatementGeneration", testInheritedUsageStatementGeneration),
            ("testMutlineUsageStatementGeneration", testMutlineUsageStatementGeneration),
            ("testCommandNotSpecified", testCommandNotSpecified),
            ("testCommandNotFound", testCommandNotFound),
            ("testMisusedOptionsStatementGeneration", testMisusedOptionsStatementGeneration),
            ("testNoCommandMisusedOption", testNoCommandMisusedOption),
            ("testExpectedValueAfterKey", testExpectedValueAfterKey),
            ("testIllegalOptionType", testIllegalOptionType),
            ("testOptionGroupMisuse", testOptionGroupMisuse),
            ("testParameterError", testParameterError),
        ]
    }
    
    // MARK: - HelpMessageGenerator.writeCommandList
    
    func testCommandListGeneration() {
        let capture = CaptureStream()
        let path = CommandGroupPath(top: CLI.createTester(commands: [alphaCmd, betaCmd], description: "A tester for SwiftCLI"))
        DefaultHelpMessageGenerator().writeCommandList(for: path, to: capture)
        capture.closeWrite()
        
        XCTAssertEqual(capture.readAll(), """
        
        Usage: tester <command> [options]
        
        A tester for SwiftCLI
        
        Commands:
          alpha           The alpha command
          beta            A beta command
          help            Prints this help information
        
        
        """)
        
        let capture2 = CaptureStream()
        let path2 = CommandGroupPath(top: CLI.createTester(commands: [alphaCmd, midGroup]))
        DefaultHelpMessageGenerator().writeCommandList(for: path2, to: capture2)
        capture2.closeWrite()
        
        XCTAssertEqual(capture2.readAll(), """
        
        Usage: tester <command> [options]
        
        Groups:
          mid             The mid level of commands
        
        Commands:
          alpha           The alpha command
          help            Prints this help information
        
        
        """)
    }
    
    func testMutlineCommandListGeneration() {
        let capture = CaptureStream()
        let path = CommandGroupPath(top: CLI.createTester(commands: [MultilineCommand(), betaCmd], description: "A tester for SwiftCLI"))
        DefaultHelpMessageGenerator().writeCommandList(for: path, to: capture)
        capture.closeWrite()
        
        XCTAssertEqual(capture.readAll(), """

        Usage: tester <command> [options]

        A tester for SwiftCLI

        Commands:
          test            A command that has multiline comments.
                          New line
          beta            A beta command
          help            Prints this help information


        """)
    }
    
    // MARK: - HelpMessageGenerator.writeUsageStatement

    func testUsageStatementGeneration() {
        let capture = CaptureStream()
        let command = TestCommand()
        let cli = CLI.createTester(commands: [command])
        let path = CommandGroupPath(top: cli).appending(command)
        DefaultHelpMessageGenerator().writeUsageStatement(for: path, to: capture)
        capture.closeWrite()
        
        XCTAssertEqual(capture.readAll(), """
        
        Usage: tester test <testName> [<testerName>] [options]

        A command to test stuff
        
        Options:
          -h, --help             Show help information for this command
          -s, --silent           Silence all test output
          -t, --times <value>    Number of times to run the test
        
        
        """)
    }

    func testLongDescriptionGeneration() {
        let capture = CaptureStream()
        let command = TestCommandWithLongDescription()
        let cli = CLI.createTester(commands: [command])
        let path = CommandGroupPath(top: cli).appending(command)
        DefaultHelpMessageGenerator().writeUsageStatement(for: path, to: capture)
        capture.closeWrite()

        XCTAssertEqual(capture.readAll(), """

        Usage: tester test [options]

        This is a long
        multiline description

        Options:
          -h, --help      Show help information for this command


        """)
    }
    
    func testInheritedUsageStatementGeneration() {
        let capture = CaptureStream()
        let cmd = TestInheritedCommand()
        let cli = CLI.createTester(commands: [cmd])
        let path = CommandGroupPath(top: cli).appending(cmd)
        DefaultHelpMessageGenerator().writeUsageStatement(for: path, to: capture)
        capture.closeWrite()
        
        XCTAssertEqual(capture.readAll(), """
        
        Usage: tester test <testName> [<testerName>] [options]

        A command to test stuff
        
        Options:
          -h, --help             Show help information for this command
          -s, --silent           Silence all test output
          -t, --times <value>    Number of times to run the test
          -v, --verbose          Show more output information
        

        """)
    }
    
    func testMutlineUsageStatementGeneration() {
        let capture = CaptureStream()
        let command = MultilineCommand()
        let cli = CLI.createTester(commands: [command])
        let path = CommandGroupPath(top: cli).appending(command)
        DefaultHelpMessageGenerator().writeUsageStatement(for: path, to: capture)
        capture.closeWrite()
        
        XCTAssertEqual(capture.readAll(), """

        Usage: tester test [options]

        A command that has multiline comments.
        New line

        Options:
          -h, --help             Show help information for this command
          -s, --silent           Silence all test output
                                 Newline
          -t, --times <value>    Number of times to run the test


        """)
    }
    
    // MARK: - HelpMessageGenerator.writeRouteErrorMessage
    
    func testCommandNotSpecified() {
        let capture = CaptureStream()
        let path = CommandGroupPath(top: CLI.createTester(commands: [alphaCmd, betaCmd], description: "A tester for SwiftCLI"))
        DefaultHelpMessageGenerator().writeRouteErrorMessage(for: RouteError(partialPath: path, notFound: nil), to: capture)
        capture.closeWrite()
        
        XCTAssertEqual(capture.readAll(), """
        
        Usage: tester <command> [options]
        
        A tester for SwiftCLI
        
        Commands:
          alpha           The alpha command
          beta            A beta command
          help            Prints this help information
        
        
        """)
    }
    
    func testCommandNotFound() {
        let capture = CaptureStream()
        let path = CommandGroupPath(top: CLI.createTester(commands: [alphaCmd, betaCmd], description: "A tester for SwiftCLI"))
        DefaultHelpMessageGenerator().writeRouteErrorMessage(for: RouteError(partialPath: path, notFound: "nope"), to: capture)
        capture.closeWrite()
        
        XCTAssertEqual(capture.readAll(), """
        
        Usage: tester <command> [options]
        
        A tester for SwiftCLI
        
        Commands:
          alpha           The alpha command
          beta            A beta command
          help            Prints this help information
        
        Error: command 'nope' not found

        
        """)
    }
    
    // MARK: - HelpMessageGenerator.writeMisusedOptionsStatement
    
    func testMisusedOptionsStatementGeneration() {
        let capture = CaptureStream()
        let command = TestCommand()
        let path = CommandGroupPath(top: CLI.createTester(commands: [command])).appending(command)
        let error = OptionError(command: path, kind: .unrecognizedOption("-a"))
        DefaultHelpMessageGenerator().writeMisusedOptionsStatement(for: error, to: capture)
        capture.closeWrite()
        
        XCTAssertEqual(capture.readAll(), """
        
        Usage: tester test <testName> [<testerName>] [options]

        A command to test stuff
        
        Options:
          -h, --help             Show help information for this command
          -s, --silent           Silence all test output
          -t, --times <value>    Number of times to run the test
        
        Error: unrecognized option '-a'
        
        
        """)
    }
    
    func testNoCommandMisusedOption() {
        let capture = CaptureStream()
        let error = OptionError(command: nil, kind: .unrecognizedOption("-a"))
        DefaultHelpMessageGenerator().writeMisusedOptionsStatement(for: error, to: capture)
        capture.closeWrite()
        
        XCTAssertEqual(capture.readAll(), """
        
        Error: unrecognized option '-a'
        
        
        """)
    }
    
    func testExpectedValueAfterKey() {
        let capture = CaptureStream()
        let command = TestCommand()
        let path = CommandGroupPath(top: CLI.createTester(commands: [command])).appending(command)
        let error = OptionError(command: path, kind: .expectedValueAfterKey("-t"))
        DefaultHelpMessageGenerator().writeMisusedOptionsStatement(for: error, to: capture)
        capture.closeWrite()
        
        XCTAssertEqual(capture.readAll(), """
        
        Usage: tester test <testName> [<testerName>] [options]

        A command to test stuff
        
        Options:
          -h, --help             Show help information for this command
          -s, --silent           Silence all test output
          -t, --times <value>    Number of times to run the test
        
        Error: expected a value to follow '-t'
        
        
        """)
    }
    
    func testIllegalOptionType() {
        let capture = CaptureStream()
        let command = TestCommand()
        let path = CommandGroupPath(top: CLI.createTester(commands: [command])).appending(command)
        let error = OptionError(command: path, kind: .illegalTypeForKey("-t", Int.self))
        DefaultHelpMessageGenerator().writeMisusedOptionsStatement(for: error, to: capture)
        capture.closeWrite()
        
        XCTAssertEqual(capture.readAll(), """
        
        Usage: tester test <testName> [<testerName>] [options]

        A command to test stuff
        
        Options:
          -h, --help             Show help information for this command
          -s, --silent           Silence all test output
          -t, --times <value>    Number of times to run the test
        
        Error: illegal value passed to '-t' (expected Int)
        
        
        """)
    }
    
    func testOptionGroupMisuse() {
        let command = ExactlyOneCmd()
        let path = CommandGroupPath(top: CLI.createTester(commands: [command])).appending(command)
        
        let capture = CaptureStream()
        let error = OptionError(command: path, kind: .optionGroupMisuse(command.optionGroups[0]))
        DefaultHelpMessageGenerator().writeMisusedOptionsStatement(for: error, to: capture)
        capture.closeWrite()
        
        XCTAssertEqual(capture.readAll(), """
        
        Usage: tester cmd [options]

        Options:
          -a, --alpha     the alpha flag
          -b, --beta      the beta flag
          -h, --help      Show help information for this command

        Error: must pass exactly one of the following: --alpha --beta
        
        
        """)
    }
    
    // MARK: - HelpMessageGenerator.writeParameterErrorMessage
    
    func testParameterError() {
        let command = Req2Opt2Cmd()
        let cli = CLI.createTester(commands: [command])
        let path = CommandGroupPath(top: cli).appending(command)
        
        let capture = CaptureStream()
        let error = ParameterError(command: path, paramIterator: ParameterIterator(command: path))
        DefaultHelpMessageGenerator().writeParameterErrorMessage(for: error, to: capture)
        capture.closeWrite()
        
        XCTAssertEqual(capture.readAll(), """

        Usage: tester cmd <req1> <req2> [<opt1>] [<opt2>] [options]

        Options:
          -h, --help      Show help information for this command

        Error: command requires between 2 and 4 arguments
        
        
        """)
    }

}
