package com.vpnex.backend.repository;

import com.vpnex.backend.model.KycDocumentType;
import com.vpnex.backend.model.SellerKycDocument;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SellerKycDocumentRepository extends JpaRepository<SellerKycDocument, String> {

  List<SellerKycDocument> findBySellerUidOrderByCreatedAtAsc(String sellerUid);

  Optional<SellerKycDocument> findByIdAndSellerUid(String id, String sellerUid);

  Optional<SellerKycDocument> findBySellerUidAndDocType(String sellerUid, KycDocumentType docType);

  void deleteByIdAndSellerUid(String id, String sellerUid);
}
