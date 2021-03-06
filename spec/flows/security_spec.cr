{% skip_file unless flag?(:with_sec_tests) %}
# Run these specs with `crystal spec -Dwith_sec_tests`

require "../spec_helper"

describe "SecTester" do
  it "tests the sign_in for dom based XSS" do
    scan_with_cleanup do |scanner|
      target = scanner.build_target(SignIns::New)
      scanner.run_check(
        scan_name: "ref: #{ENV["GITHUB_REF"]?} commit: #{ENV["GITHUB_SHA"]?} run id: #{ENV["GITHUB_RUN_ID"]?}",
        tests: "dom_xss",
        target: target
      )
    end
  end

  it "tests the sign_in page for SQLi, OSI, XSS attacks" do
    scan_with_cleanup do |scanner|
      target = scanner.build_target(SignIns::Create) do |t|
        t.body = "user%3Aemail=test%40test.com&user%3Apassword=1234"
      end
      scanner.run_check(
        scan_name: "ref: #{ENV["GITHUB_REF"]?} commit: #{ENV["GITHUB_SHA"]?} run id: #{ENV["GITHUB_RUN_ID"]?}",
        tests: [
          "sqli", # Testing for SQL Injection issues (https://docs.neuralegion.com/docs/sql-injection)
          "osi",
          "xss",
        ],
        target: target
      )
    end
  end

  it "tests the sign_up page for dom based XSS" do
    scan_with_cleanup do |scanner|
      target = scanner.build_target(SignUps::New)
      scanner.run_check(
        scan_name: "ref: #{ENV["GITHUB_REF"]?} commit: #{ENV["GITHUB_SHA"]?} run id: #{ENV["GITHUB_RUN_ID"]?}",
        tests: "dom_xss",
        target: target
      )
    end
  end

  it "tests the sign_up page for ALL attacks" do
    scan_with_cleanup do |scanner|
      target = scanner.build_target(SignUps::Create) do |t|
        t.body = "user%3Aemail=aa%40aa.com&user%3Apassword=123456789&user%3Apassword_confirmation=123456789"
      end
      scanner.run_check(
        scan_name: "ref: #{ENV["GITHUB_REF"]?} commit: #{ENV["GITHUB_SHA"]?} run id: #{ENV["GITHUB_RUN_ID"]?}",
        tests: nil,
        target: target
      )
    end
  end
  it "tests the home page for header, and cookie security issues" do
    scan_with_cleanup do |scanner|
      target = scanner.build_target(Home::Index)
      scanner.run_check(
        scan_name: "ref: #{ENV["GITHUB_REF"]?} commit: #{ENV["GITHUB_SHA"]?} run id: #{ENV["GITHUB_RUN_ID"]?}",
        severity_threshold: SecTester::Severity::Medium,
        tests: [
          "header_security",
          "cookie_security",
        ],
        target: target
      )
    end
  end

  it "tests app.js for 3rd party issues" do
    scan_with_cleanup do |scanner|
      target = SecTester::Target.new(Lucky::RouteHelper.settings.base_uri + Lucky::AssetHelpers.asset("js/app.js"))
      scanner.run_check(
        scan_name: "ref: #{ENV["GITHUB_REF"]?} commit: #{ENV["GITHUB_SHA"]?} run id: #{ENV["GITHUB_RUN_ID"]?}",
        tests: "retire_js",
        target: target
      )
    end
  end
end

private def scan_with_cleanup : Nil
  scanner = LuckySecTester.new
  yield scanner
ensure
  scanner.try &.cleanup
end
