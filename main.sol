// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TokenConImpuesto is ERC20, Ownable, Pausable {

    // --- Variables de Estado ---
    address public treasury;
    uint256 public taxFee;
    mapping(address => bool) private _isFeeExempt;

    // --- Eventos ---
    event TreasuryUpdated(address newTreasury);
    event TaxFeeUpdated(uint256 newFee);
    event FeeExemptionUpdated(address indexed account, bool isExempt);

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        address initialOwner,
        address initialTreasury,
        uint256 initialTaxFee
    ) ERC20(name, symbol) Ownable(initialOwner) {
        require(initialTreasury != address(0), "La tesoreria no puede ser la direccion cero");
        require(initialTaxFee <= 100, "El impuesto no puede ser mayor a 100");

        treasury = initialTreasury;
        taxFee = initialTaxFee;
        _isFeeExempt[initialOwner] = true;
        _isFeeExempt[initialTreasury] = true;
        
        _mint(initialOwner, 1_000_000 * (10**decimals()));
    }

    // --- Funciones de Solo Propietario (Ownable) ---
    // (Estas funciones permanecen sin cambios)
    function setTreasury(address newTreasury) public onlyOwner {
        require(newTreasury != address(0), "La tesoreria no puede ser la direccion cero");
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }

    function setTaxFee(uint256 newFee) public onlyOwner {
        require(newFee <= 100, "El impuesto no puede ser mayor a 100");
        taxFee = newFee;
        emit TaxFeeUpdated(newFee);
    }

    function setFeeExemption(address account, bool isExempt) public onlyOwner {
        _isFeeExempt[account] = isExempt;
        emit FeeExemptionUpdated(account, isExempt);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Funciones de Lectura (View) ---
    function isFeeExempt(address account) public view returns (bool) {
        return _isFeeExempt[account];
    }

    // --- Lógica Principal del Token ---
    // SE REEMPLAZA _transfer POR _update
    function _update(address from, address to, uint256 amount) internal override whenNotPaused {
        // Si no se debe aplicar impuesto, ejecuta la transferencia normal y termina.
        if (taxFee == 0 || _isFeeExempt[from] || _isFeeExempt[to] || from == address(0) || to == address(0)) {
            super._update(from, to, amount); //
            return;
        }

        // Si se aplica impuesto, se divide la transferencia en dos.
        uint256 feeAmount = (amount * taxFee) / 100;
        uint256 netAmount = amount - feeAmount;

        // 1. Envía el impuesto a la tesorería
        if (feeAmount > 0) {
            super._update(from, treasury, feeAmount); //
        }
        
        // 2. Envía el monto neto al destinatario
        if (netAmount > 0) {
            super._update(from, to, netAmount); //
        }
    }
}