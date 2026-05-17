from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import landscape
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas


slides = [
    ("On-Chain Prediction Market", ["Upgradeable binary markets", "ERC20Votes governance + Timelock", "ERC1155 outcome shares and ERC4626 fee vault", "Foundry: 86 tests passing"]),
    ("Problem", ["Prediction markets need transparent market creation, reliable resolution, auditable payouts, and governance controls.", "The project demonstrates a protocol surface, not only one isolated contract."]),
    ("Architecture", ["UUPS PredictionMarket proxy is the core.", "OracleAdapter wraps Chainlink-style feed checks.", "GovernanceToken, PredictionGovernor, and TimelockController control admin actions."]),
    ("Smart Contracts", ["PredictionMarket: lifecycle, buying, resolving, claiming, fees", "MarketFactory: CREATE and CREATE2 deployment", "OutcomeToken: ERC1155 YES/NO token IDs", "FeeVault: ERC4626 collateral vault"]),
    ("Governance Flow", ["Tested lifecycle: propose -> vote -> queue -> timelock delay -> execute.", "The proposal executes MarketFactory.deployToken through TimelockController.", "Parameters: 1 day delay, 1 week period, 4% quorum, 2 day timelock."]),
    ("Security", ["Owner-only privileged functions", "UUPS owner initialization fixed", "ReentrancyGuard on token-flow functions", "Checks-Effects-Interactions for accounting", "SafeERC20 transfers and oracle staleness checks"]),
    ("Testing", ["86 tests passed, 0 failed, 0 skipped", "Unit, fuzz, invariant, and optional fork-safe tests", "ERC1155, ERC4626, and Governor lifecycle tests included."]),
    ("Frontend + Subgraph", ["Frontend scaffold: wallet connect, reads, create market, delegate, vote, subgraph query.", "Subgraph entities: Market, SharePurchase, Resolution, FeeWithdrawal."]),
    ("Deployment", ["Deploy.s.sol deploys the full protocol stack.", "PostDeployCheck.s.sol verifies Governor, Timelock, and factory ownership.", "Real L2 addresses require PRIVATE_KEY and RPC_URL in local .env."]),
    ("Defence Demo Plan", ["Run forge build and forge test.", "Show PredictionMarket, PredictionGovernor, OutcomeToken, FeeVault.", "Explain remaining network-only deployment steps."]),
]


def draw_wrapped(c, text, x, y, max_chars=90):
    words = text.split()
    line = ""
    for word in words:
        test = (line + " " + word).strip()
        if len(test) > max_chars and line:
            c.drawString(x, y, line)
            y -= 0.3 * inch
            line = word
        else:
            line = test
    if line:
        c.drawString(x, y, line)
        y -= 0.3 * inch
    return y


def main():
    out = Path(__file__).with_name("final-presentation.pdf")
    width, height = landscape((13.333 * inch, 7.5 * inch))
    deck = canvas.Canvas(str(out), pagesize=(width, height))

    for index, (title, bullets) in enumerate(slides, start=1):
        deck.setFillColor(colors.HexColor("#0f172a"))
        deck.rect(0, 0, width, height, fill=1, stroke=0)
        deck.setFillColor(colors.HexColor("#38bdf8"))
        deck.setFont("Helvetica-Bold", 12)
        deck.drawString(0.65 * inch, height - 0.55 * inch, f"PREDICTION MARKET FINAL PROJECT | {index:02d}/10")
        deck.setFillColor(colors.white)
        deck.setFont("Helvetica-Bold", 34)
        deck.drawString(0.65 * inch, height - 1.35 * inch, title)
        deck.setStrokeColor(colors.HexColor("#38bdf8"))
        deck.setLineWidth(2)
        deck.line(0.65 * inch, height - 1.62 * inch, 12.6 * inch, height - 1.62 * inch)

        y = height - 2.25 * inch
        for bullet in bullets:
            deck.setFillColor(colors.HexColor("#38bdf8"))
            deck.circle(0.83 * inch, y + 0.08 * inch, 4, fill=1, stroke=0)
            deck.setFillColor(colors.HexColor("#e5e7eb"))
            deck.setFont("Helvetica", 20)
            y = draw_wrapped(deck, bullet, 1.05 * inch, y)
            y -= 0.23 * inch

        deck.setFillColor(colors.HexColor("#64748b"))
        deck.setFont("Helvetica", 10)
        deck.drawRightString(width - 0.65 * inch, 0.35 * inch, "Generated for defence submission")
        deck.showPage()

    deck.save()
    print(out)


if __name__ == "__main__":
    main()
