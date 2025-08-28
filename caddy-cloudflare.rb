class CaddyCloudflare < Formula
  desc "Powerful, enterprise-ready, open source web server with automatic HTTPS and also cloudflare"
  homepage "https://caddyserver.com/"
  url "https://github.com/caddyserver/caddy/archive/v2.7.6.tar.gz"
  sha256 "e1c524fc4f4bd2b0d39df51679d9d065bb811e381b7e4e51466ba39a0083e3ed"
  license "Apache-2.0"
  head "https://github.com/caddyserver/caddy.git", branch: "master"

  depends_on "go" => :build

  resource "xcaddy" do
    url "https://github.com/caddyserver/xcaddy/archive/refs/tags/v0.4.4.tar.gz"
    sha256 "5ba32eec2388638cebbe1df861ea223c35074528af6a0424f07e436f07adce72"
  end

  def install
    revision = build.head? ? version.commit : "v#{version}"

    resource("xcaddy").stage do
      system "go", "run", "cmd/xcaddy/main.go", "build", revision, "--with", "github.com/caddy-dns/cloudflare", "--output",
bin/"caddy"
    end

    generate_completions_from_executable("go", "run", "cmd/caddy/main.go", "completion")
  end

  service do
    run [opt_bin/"caddy", "run", "--config", etc/"Caddyfile"]
    keep_alive true
    error_log_path var/"log/caddy.log"
    log_path var/"log/caddy.log"
  end

  test do
    port1 = free_port
    port2 = free_port

    (testpath/"Caddyfile").write <<~EOS
      {
        admin 127.0.0.1:#{port1}
      }

      http://127.0.0.1:#{port2} {
        respond "Hello, Caddy!"
      }
    EOS

    fork do
      exec bin/"caddy", "run", "--config", testpath/"Caddyfile"
    end
    sleep 2

    assert_match "\":#{port2}\"",
      shell_output("curl -s http://127.0.0.1:#{port1}/config/apps/http/servers/srv0/listen/0")
    assert_match "Hello, Caddy!", shell_output("curl -s http://127.0.0.1:#{port2}")

    assert_match version.to_s, shell_output("#{bin}/caddy version")
  end
end
