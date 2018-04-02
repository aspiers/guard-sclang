/*
	Simple frontend to UnitTest to allow running tests from the CLI,
	and obtain success or failure via the exit code.

	Example invocations:

	// Run all subclasses of UnitTest
	sclang unit-test.sc

	// Run all tests in TestMyClass:
	sclang unit-test.sc TestMyClass

	// You can also reference the test filename, but this assumes 1:1
	// mapping between class filenames and class names:
	sclang unit-test.sc lib/tests/TestMyClass.sc

	// Run a specific method:
	sclang unit-test.sc TestMyClass:test_my_method

	Multiple arguments are supported.
*/

// Exclude slow built-in tests for now.
// FIXME: make this configurable.
var excludes = [
	"MixedBundleTester",
	"UnitTest",
	"TestScript"
];

// Have to wrap this in a Task so that we can wait.
t = Task.new {
	UnitTest.reset;
	//UnitTest.reportPasses = false;
	UnitTest.passVerbosity = UnitTest.brief;
	if (thisProcess.argv.isEmpty) {
		UnitTest.allSubclasses.do { |testClass|
			if (excludes.includes(testClass.asString).not) {
				testClass.run(false, false);
				// FIXME: can't remember what this is for, but it
				// doesn't look good:
				0.1.wait;
			};
			UnitTest.report;
		};
	} {
		thisProcess.argv.do { |name|
			if (name.contains("/")) {
				name = PathName(name.basename).fileNameWithoutExtension;
			};
			if (name.contains(":")) {
				UnitTest.runTest(name);
			} {
				var className = name;
				var klass = className.asSymbol.asClass;
				if (klass.isNil) {
					var msg = "% is not a valid class name; skipping.".format(className);
					UnitTest.new.failed(nil, msg, true);
				} {
					"Invoking %.run".format(className).postln;
					klass.run(reset: false);
				};
			};
		};
	};
	"Finished running test(s): % passes, % failures\n".postf(
		UnitTest.passes.size,
		UnitTest.failures.size
	);
	UnitTest.failures.size.exit;
};
t.start;
