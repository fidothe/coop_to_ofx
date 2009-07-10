# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{coop_to_ofx}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Your name"]
  s.date = %q{2009-07-10}
  s.email = %q{you@example.com}
  s.executables = ["coop_cc_ofx", "coop_curr_ofx", "coop_to_ofx"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["OFX", "2.0.3", "Schema.zip", "2.1.1", "schema.zip", "203.pdf", "Rakefile", "README.rdoc", "sample_data.ofx", "bin/coop_cc_ofx", "bin/coop_curr_ofx", "bin/coop_to_ofx", "spec/coop_scraper", "spec/coop_scraper/base_spec.rb", "spec/coop_scraper/credit_card_spec.rb", "spec/coop_scraper/current_account_spec.rb", "spec/fixtures", "spec/fixtures/credit_card", "spec/fixtures/credit_card/cc_statement_fixture.html", "spec/fixtures/credit_card/foreign_transaction_fixture.html", "spec/fixtures/credit_card/interest_transaction_fixture.html", "spec/fixtures/credit_card/maybe.txt", "spec/fixtures/credit_card/merchandise_interest_fixture.html", "spec/fixtures/credit_card/normal_transaction_fixture.html", "spec/fixtures/credit_card/overlimit_charge_fixture.html", "spec/fixtures/credit_card/payment_in_transaction_fixture.html", "spec/fixtures/credit_card/simple_cc_statement.ofx", "spec/fixtures/credit_card/statement_with_interest_line_fixture.html", "spec/fixtures/current_account", "spec/fixtures/current_account/cash_point_transaction_fixture.html", "spec/fixtures/current_account/current_account_fixture.html", "spec/fixtures/current_account/current_account_fixture.ofx", "spec/fixtures/current_account/debit_interest_transaction_fixture.html", "spec/fixtures/current_account/no_transactions_fixture.html", "spec/fixtures/current_account/normal_transaction_fixture.html", "spec/fixtures/current_account/payment_in_transaction_fixture.html", "spec/fixtures/current_account/service_charge_transaction_fixture.html", "spec/fixtures/current_account/transfer_transaction_fixture.html", "spec/ofx", "spec/ofx/statement", "spec/ofx/statement/base_spec.rb", "spec/ofx/statement/credit_card_spec.rb", "spec/ofx/statement/current_account_spec.rb", "spec/ofx/statement/output", "spec/ofx/statement/output/base_spec.rb", "spec/ofx/statement/output/builder_spec.rb", "spec/ofx/statement/output/credit_card_spec.rb", "spec/ofx/statement/output/current_account_spec.rb", "spec/ofx/statement/transaction_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "lib/coop_scraper", "lib/coop_scraper/base.rb", "lib/coop_scraper/credit_card.rb", "lib/coop_scraper/current_account.rb", "lib/coop_scraper/version.rb", "lib/coop_scraper.rb", "lib/ofx", "lib/ofx/statement", "lib/ofx/statement/base.rb", "lib/ofx/statement/credit_card.rb", "lib/ofx/statement/current_account.rb", "lib/ofx/statement/output", "lib/ofx/statement/output/base.rb", "lib/ofx/statement/output/builder.rb", "lib/ofx/statement/output/credit_card.rb", "lib/ofx/statement/output/current_account.rb", "lib/ofx/statement/transaction.rb", "lib/ofx/statement.rb", "lib/ofx.rb"]
  s.homepage = %q{http://example.com}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{coop_to_ofx}
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{What this thing does}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
