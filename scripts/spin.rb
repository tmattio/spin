class Spin < Formula
  VERSION = '0.3.12'
  desc 'Project scaffolding tool and set of templates for Reason and OCaml.'
  homepage 'https://github.com/tmattio/spin'
  url "https://github.com/tmattio/spin/releases/download/v#{VERSION}/spin-darwin-x64.tar.gz"
  version VERSION

  bottle :unneeded

  test do
    system "#{bin}/spin", '--version'
  end

  def install
    bin.install 'spin'
  end
end
